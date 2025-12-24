# Azgaar Serverless Issue Investigation Audit

**Generated:** 2025-01-20  
**Purpose:** Investigate and document the root cause of Azgaar Fantasy Map Generator's "cannot run serverless" error when loaded via `file://` protocol in godot_wry WebView, and propose solutions for embedded HTTP server implementation.

---

## 1. Executive Summary

The Azgaar Fantasy Map Generator integration in the World Builder UI fails to load when accessed via `file://` protocol, displaying an error popup: **"Fantasy Map Generator cannot run serverless. Follow the instructions on how to easily run a local web-server"**. This prevents the full Azgaar interface and map from loading in the embedded WebView (godot_wry), showing only the loading screen with compass and the error dialog.

**Root Cause:** Azgaar's `main.js` contains a serverless detection check (`if (!location.hostname)`) that triggers when the page is loaded via `file://` protocol. This check exists because Azgaar uses ES modules, Web Workers, and other browser features that require HTTP/HTTPS protocol due to CORS and security restrictions.

**Recommended Solution:** Implement an embedded HTTP server in Godot using `TCPServer` and `StreamPeerTCP` to serve Azgaar files from `user://azgaar/` on `http://127.0.0.1:port/index.html`, then load the WebView with the HTTP URL instead of `file://`.

---

## 2. Current Status

### 2.1 Error Confirmation

**Error Message:**
```
Fantasy Map Generator cannot run serverless. Follow the instructions on how you can easily run a local web-server
```

**Location in Code:**
- **File:** `tools/azgaar/main.js`
- **Line:** 262
- **Context:** Triggered in `DOMContentLoaded` event listener (line 259)

**Current URL Loading:**
- **Method:** `AzgaarIntegrator.get_azgaar_url()` returns `file://` URL
- **Format:** `file:///home/user/.local/share/godot/app_userdata/genesis-mythos/azgaar/index.html`
- **WebView:** godot_wry `WebView` node loads this URL via `load_url()`

**Observed Behavior:**
- WebView displays Azgaar loading screen (compass animation)
- Error dialog appears with the serverless message
- Map generation interface does not load
- JavaScript execution fails due to module loading restrictions

### 2.2 Relevant Files

#### Core Integration Files
- **Manager:** `res://scripts/managers/AzgaarIntegrator.gd` (111 lines)
  - `get_azgaar_url()` - Returns `file://` URL (line 105-110)
  - `copy_azgaar_to_user()` - Copies files to `user://azgaar/` (line 16-42)

- **WebView Controller:** `res://scripts/ui/WorldBuilderAzgaar.gd` (344 lines)
  - `_initialize_webview()` - Loads URL via `web_view.load_url(url)` (line 57)
  - Uses `azgaar_integrator.get_azgaar_url()` to get file path

#### Azgaar Source Files
- **Entry Point:** `tools/azgaar/index.html` (8,185+ lines)
- **Main Script:** `tools/azgaar/main.js` (1,295+ lines)
  - **Line 260:** `if (!location.hostname)` - Serverless detection
  - **Line 262:** Error message display
  - **Line 275:** Normal execution path (`else` block)

#### Server Scripts (Reference Only)
- `tools/azgaar/run_python_server.sh` - Python HTTP server script
- `tools/azgaar/run_python_server.bat` - Windows Python server script
- `tools/azgaar/run_php_server.bat` - PHP server script
- `tools/azgaar/Dockerfile` - Nginx container setup

---

## 3. Root Cause Analysis

### 3.1 Technical Reasons for Serverless Detection

**Primary Check:**
```javascript
if (!location.hostname) {
    // Show error dialog
}
```

**Why This Fails with `file://`:**
1. **Protocol Difference:**
   - `file://` URLs have no hostname (empty string)
   - `http://`/`https://` URLs have hostname (e.g., `127.0.0.1`, `localhost`)
   - `location.hostname` is `""` for `file://` protocol

2. **Browser Security Restrictions:**
   - **CORS:** Cross-Origin Resource Sharing blocks `file://` requests for modules
   - **ES Modules:** Modern JavaScript `import` statements require HTTP/HTTPS
   - **Web Workers:** Worker scripts cannot load from `file://` protocol
   - **Fetch API:** Limited functionality with `file://` protocol
   - **Service Workers:** Not supported on `file://` protocol

3. **Azgaar's Dependencies:**
   - Uses ES6 modules (`import`/`export`)
   - Uses Web Workers for heavy computation (heightmap generation, pathfinding)
   - Uses Fetch API for loading assets
   - Uses D3.js and other libraries that expect HTTP context

### 3.2 Code Analysis

**Serverless Detection Logic:**
```javascript:259:281:tools/azgaar/main.js
document.addEventListener("DOMContentLoaded", async () => {
  if (!location.hostname) {
    const wiki = "https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Run-FMG-locally";
    alertMessage.innerHTML = /* html */ `Fantasy Map Generator cannot run serverless. Follow the <a href="${wiki}" target="_blank">instructions</a> on how you can easily run a local web-server`;

    $("#alert").dialog({
      resizable: false,
      title: "Loading error",
      width: "28em",
      position: {my: "center center-4em", at: "center", of: "svg"},
      buttons: {
        OK: function () {
          $(this).dialog("close");
        }
      }
    });
  } else {
    hideLoading();
    await checkLoadParameters();
  }
  restoreDefaultEvents(); // apply default viewbox events
  initiateAutosave();
});
```

**Current URL Generation:**
```gdscript:105:110:scripts/managers/AzgaarIntegrator.gd
func get_azgaar_url() -> String:
	"""Get the file:// URL path to Azgaar index.html in user:// directory."""
	var user_path := OS.get_user_data_dir()
	var azgaar_path := user_path.path_join("azgaar").path_join("index.html")
	# Convert to file:// URL format
	return "file://" + azgaar_path
```

**WebView Loading:**
```gdscript:50:58:scripts/ui/WorldBuilderAzgaar.gd
	# Initialize Azgaar
	if azgaar_integrator:
		azgaar_integrator.copy_azgaar_to_user()
		var url: String = azgaar_integrator.get_azgaar_url()
		
		# Load Azgaar URL
		if web_view.has_method("load_url"):
			web_view.load_url(url)
			MythosLogger.info("WorldBuilderAzgaar", "Loaded Azgaar URL", {"url": url})
```

### 3.3 External Research Context

**Common Causes (Based on Known Web Standards):**

1. **ES Module Loading:**
   - ES modules require HTTP/HTTPS protocol per HTML5 specification
   - `file://` protocol is explicitly excluded from module loading for security
   - Browsers enforce this restriction strictly

2. **Web Worker Restrictions:**
   - Workers cannot be instantiated from `file://` URLs
   - Azgaar uses workers for:
     - Heightmap generation
     - Voronoi diagram calculation
     - Pathfinding algorithms
     - Large dataset processing

3. **CORS Policy:**
   - `file://` protocol has no origin, causing CORS failures
   - Asset loading (images, JSON, etc.) fails silently or throws errors
   - Fetch API returns opaque responses or errors

4. **Service Worker Limitations:**
   - Service workers require HTTPS (or localhost HTTP)
   - `file://` protocol cannot register service workers
   - Offline functionality breaks

**Azgaar's Official Recommendation:**
- GitHub wiki: https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Run-FMG-locally
- Suggests using Python's `http.server`, PHP's built-in server, or Node.js `http-server`
- All solutions require HTTP protocol on localhost

---

## 4. Potential Solutions

### 4.1 Solution 1: Embedded HTTP Server in Godot (RECOMMENDED)

**Priority:** ⭐⭐⭐⭐⭐ (Highest)

**Description:**
Implement a minimal HTTP server in GDScript using Godot's `TCPServer` and `StreamPeerTCP` classes to serve files from `user://azgaar/` directory on `http://127.0.0.1:PORT/index.html`.

**Implementation Approach:**
1. Create `AzgaarServer.gd` singleton or manager class
2. Use `TCPServer` to listen on a local port (e.g., 8080)
3. Parse HTTP GET requests (minimal HTTP/1.1 support)
4. Serve files from `user://azgaar/` with proper MIME types
5. Handle directory listing for assets (images, CSS, JS)
6. Start server on `_ready()` or when World Builder UI opens
7. Stop server when World Builder UI closes or on exit

**Advantages:**
- ✅ No external dependencies
- ✅ Cross-platform (works on Windows, Linux, macOS)
- ✅ Integrated with Godot lifecycle
- ✅ Automatic port management
- ✅ No subprocess overhead
- ✅ Full control over serving logic

**Disadvantages:**
- ⚠️ Requires HTTP parsing implementation (minimal but non-trivial)
- ⚠️ Must handle MIME types correctly for assets
- ⚠️ Port conflicts possible (need fallback port selection)
- ⚠️ Performance overhead (minimal for localhost)

**Estimated Complexity:** Medium (200-300 lines of GDScript)

**Files to Create:**
- `res://scripts/managers/AzgaarServer.gd` - HTTP server implementation
- Update `res://scripts/managers/AzgaarIntegrator.gd` - Add `get_azgaar_http_url()` method
- Update `res://scripts/ui/WorldBuilderAzgaar.gd` - Use HTTP URL instead of file://

**Port Selection Strategy:**
- Try port 8080 first (common development port)
- If busy, try 8081, 8082, etc. (up to 8090)
- Log selected port for debugging
- Store port in singleton for URL generation

**MIME Type Mapping:**
```gdscript
const MIME_TYPES = {
    "html": "text/html",
    "js": "application/javascript",
    "json": "application/json",
    "css": "text/css",
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "svg": "image/svg+xml",
    "webmanifest": "application/manifest+json",
    # ... etc
}
```

### 4.2 Solution 2: Modify Azgaar Code to Bypass Check (NOT RECOMMENDED)

**Priority:** ⭐ (Lowest - Last Resort)

**Description:**
Comment out or modify the serverless detection check in `tools/azgaar/main.js` to allow `file://` protocol execution.

**Implementation:**
- Modify line 260: `if (!location.hostname)` → `if (false && !location.hostname)`
- Or add exception: `if (!location.hostname && !window.godot_embedded)`

**Advantages:**
- ✅ Quick fix (one line change)
- ✅ No server implementation needed

**Disadvantages:**
- ❌ **Will break:** ES modules still won't load
- ❌ **Will break:** Web Workers won't work
- ❌ **Will break:** Asset loading will fail
- ❌ **Will break:** Fetch API will fail
- ❌ Maintenance burden (must patch on every Azgaar update)
- ❌ Violates Azgaar's intended usage
- ❌ May cause runtime errors in Azgaar code

**Verdict:** **DO NOT USE** - This will only hide the error dialog but won't fix the underlying issues. Azgaar will still fail to function properly.

### 4.3 Solution 3: Use Pre-built HTTP Server Addon (IF AVAILABLE)

**Priority:** ⭐⭐⭐ (Medium - If Available)

**Description:**
Check if an existing Godot addon provides HTTP server functionality (e.g., `godot-http-server`, `simple-http-server`).

**Implementation:**
1. Search Godot Asset Library or GitHub for HTTP server addons
2. If found, integrate into project
3. Configure to serve `user://azgaar/` directory
4. Use addon's API to get server URL

**Advantages:**
- ✅ Pre-tested implementation
- ✅ May have advanced features (caching, compression)
- ✅ Community support

**Disadvantages:**
- ⚠️ External dependency
- ⚠️ May not exist or be maintained
- ⚠️ May have different API than needed
- ⚠️ License compatibility concerns

**Current Status:** **UNKNOWN** - Requires research. No HTTP server addons currently in `res://addons/` directory.

### 4.4 Solution 4: Launch External Server Subprocess (NOT RECOMMENDED)

**Priority:** ⭐⭐ (Low - Cross-Platform Issues)

**Description:**
Launch Python/PHP/Node.js HTTP server as subprocess using `OS.execute()` or `OS.create_process()`.

**Implementation:**
- Detect available runtime (Python 3, PHP, Node.js)
- Launch appropriate server command
- Parse output to get port
- Clean up on exit

**Advantages:**
- ✅ Uses proven server implementations
- ✅ Full HTTP/1.1 support
- ✅ Proper MIME types

**Disadvantages:**
- ❌ **Cross-platform complexity:** Different commands per OS
- ❌ **Dependency requirement:** Users must have Python/PHP/Node installed
- ❌ **Process management:** Must track and kill subprocess
- ❌ **Port conflicts:** External process may fail to bind
- ❌ **Error handling:** Difficult to detect subprocess failures
- ❌ **Security concerns:** Launching external processes

**Verdict:** **NOT RECOMMENDED** - Too many cross-platform and dependency issues. Only use if Solution 1 proves impossible.

---

## 5. Implementation Plan: Embedded HTTP Server (Solution 1)

### 5.1 Phase 1: Create HTTP Server Class

**File:** `res://scripts/managers/AzgaarServer.gd`

**Key Components:**
1. **TCPServer Setup:**
   - `var server: TCPServer = TCPServer.new()`
   - Port selection with fallback (8080-8090)
   - `server.listen(port, "127.0.0.1")`

2. **Request Handling:**
   - `_process()` loop to accept connections
   - Parse HTTP GET request (extract path)
   - Map path to `user://azgaar/` file system
   - Read file content
   - Send HTTP response with headers

3. **HTTP Response Format:**
   ```
   HTTP/1.1 200 OK
   Content-Type: text/html
   Content-Length: 1234
   
   <file content>
   ```

4. **MIME Type Detection:**
   - Extract file extension
   - Look up in MIME_TYPES dictionary
   - Default to `application/octet-stream`

5. **Error Handling:**
   - 404 for missing files
   - 500 for read errors
   - Proper HTTP status codes

**Estimated Lines:** 200-250

### 5.2 Phase 2: Integrate with AzgaarIntegrator

**File:** `res://scripts/managers/AzgaarIntegrator.gd`

**Changes:**
1. Add `@onready var azgaar_server: Node = get_node_or_null("/root/AzgaarServer")`
2. Add method `get_azgaar_http_url() -> String`:
   ```gdscript
   func get_azgaar_http_url() -> String:
       """Get the http:// URL to Azgaar index.html via embedded server."""
       if azgaar_server and azgaar_server.is_server_running():
           var port = azgaar_server.get_port()
           return "http://127.0.0.1:%d/index.html" % port
       return ""  # Fallback to file:// if server not available
   ```
3. Ensure server starts before URL is requested

**Estimated Lines:** +15-20

### 5.3 Phase 3: Update WorldBuilderAzgaar to Use HTTP URL

**File:** `res://scripts/ui/WorldBuilderAzgaar.gd`

**Changes:**
1. Modify `_initialize_webview()`:
   ```gdscript
   var url: String = azgaar_integrator.get_azgaar_http_url()
   if url.is_empty():
       url = azgaar_integrator.get_azgaar_url()  # Fallback to file://
   ```
2. Add error handling if HTTP URL unavailable
3. Log which URL type is being used

**Estimated Lines:** +5-10

### 5.4 Phase 4: Add Server Lifecycle Management

**Options:**
- **Option A:** Singleton autoload (`AzgaarServer` in project.godot)
  - Starts on project launch
  - Runs until project exits
  - Simple but always running

- **Option B:** Manager in World Builder UI
  - Starts when World Builder UI opens
  - Stops when World Builder UI closes
  - More efficient, but requires cleanup

**Recommendation:** **Option A (Singleton)** for simplicity and reliability.

### 5.5 Phase 5: Testing & Validation

**Test Cases:**
1. ✅ Server starts and binds to port successfully
2. ✅ `index.html` loads via HTTP URL
3. ✅ No "serverless" error dialog appears
4. ✅ Azgaar interface loads completely
5. ✅ JavaScript modules load correctly
6. ✅ Assets (images, CSS, JS) load correctly
7. ✅ Map generation works
8. ✅ Port conflict handling (if 8080 busy, use 8081)
9. ✅ Server stops cleanly on exit
10. ✅ Multiple World Builder UI opens don't create duplicate servers

---

## 6. Risks & Mitigations

### 6.1 Performance Impact

**Risk:** HTTP server adds CPU/memory overhead

**Mitigation:**
- Server only handles localhost connections (minimal network overhead)
- Single-threaded request handling (one connection at a time)
- Simple file serving (no complex processing)
- **Expected Impact:** Negligible (<1% CPU, <10MB RAM)

### 6.2 Port Conflicts

**Risk:** Port 8080 (or fallback ports) may be in use by other applications

**Mitigation:**
- Implement port scanning (try 8080, 8081, ..., 8090)
- Log selected port for debugging
- Store port in singleton for consistent URL generation
- **Fallback:** If all ports busy, show error message to user

### 6.3 Cross-Platform Compatibility

**Risk:** TCPServer behavior may differ on Windows/Linux/macOS

**Mitigation:**
- Test on all three platforms
- Use `127.0.0.1` (not `localhost`) for consistent binding
- Handle platform-specific errors gracefully
- **Note:** Godot's TCPServer is cross-platform, but edge cases exist

### 6.4 Security Concerns

**Risk:** Local HTTP server could be accessed by other applications

**Mitigation:**
- Bind only to `127.0.0.1` (localhost, not `0.0.0.0`)
- No external network access
- Serve only `user://azgaar/` directory (no directory traversal)
- Validate file paths to prevent `../` attacks
- **Risk Level:** Low (localhost only, no external exposure)

### 6.5 File Path Handling

**Risk:** Incorrect path mapping between HTTP requests and file system

**Mitigation:**
- Sanitize request paths (remove `..`, leading slashes)
- Map `/index.html` → `user://azgaar/index.html`
- Map `/images/logo.png` → `user://azgaar/images/logo.png`
- Handle URL encoding/decoding correctly
- **Test:** Verify all Azgaar assets load correctly

### 6.6 Server Lifecycle

**Risk:** Server may not start/stop cleanly, causing resource leaks

**Mitigation:**
- Implement proper cleanup in `_exit_tree()`
- Close all active connections on shutdown
- Use Godot's signal system for lifecycle management
- **Test:** Verify no port binding errors on restart

---

## 7. Testing Plan

### 7.1 Unit Tests (GUT Framework)

**File:** `res://tests/managers/AzgaarServerTest.gd`

**Test Cases:**
1. `test_server_starts_successfully()` - Server binds to port
2. `test_port_fallback()` - Falls back if port busy
3. `test_http_request_parsing()` - Parses GET requests correctly
4. `test_file_serving()` - Serves index.html correctly
5. `test_mime_type_detection()` - Returns correct MIME types
6. `test_404_handling()` - Returns 404 for missing files
7. `test_path_sanitization()` - Prevents directory traversal
8. `test_server_stops_cleanly()` - Cleanup on exit

### 7.2 Integration Tests

**Manual Testing Checklist:**
- [ ] Start Godot project
- [ ] Navigate to World Builder UI
- [ ] Verify Azgaar WebView loads without error
- [ ] Verify no "serverless" error dialog
- [ ] Verify Azgaar interface is fully interactive
- [ ] Verify map generation works
- [ ] Verify assets (images, CSS) load correctly
- [ ] Verify JavaScript console has no errors
- [ ] Close World Builder UI
- [ ] Restart World Builder UI (verify server reuses port)
- [ ] Test with port 8080 already in use (verify fallback)

### 7.3 Performance Tests

**Metrics to Monitor:**
- Server startup time (<100ms target)
- Request response time (<10ms target for localhost)
- Memory usage (<10MB additional)
- CPU usage (<1% idle, <5% under load)

**Tools:**
- Godot's built-in profiler
- `MythosLogger` for timing logs
- System monitor for resource usage

### 7.4 Cross-Platform Tests

**Platforms:**
- [ ] Linux (Ubuntu 22.04+)
- [ ] Windows 10/11
- [ ] macOS (if available)

**Test Focus:**
- Port binding behavior
- File path handling (Windows vs Unix)
- Server lifecycle (start/stop)
- Error handling

---

## 8. Alternative Considerations

### 8.1 Why Not Use Existing Solutions?

**Python `http.server`:**
- Requires Python installation (not guaranteed)
- Cross-platform command differences
- Process management complexity
- **Verdict:** Too many dependencies

**Node.js `http-server`:**
- Requires Node.js installation
- npm package management
- **Verdict:** Too many dependencies

**PHP Built-in Server:**
- Requires PHP installation
- **Verdict:** Too many dependencies

**Embedded Solution (Recommended):**
- Zero external dependencies
- Full control
- Integrated with Godot lifecycle
- **Verdict:** Best fit for embedded use case

### 8.2 Future Enhancements

**Potential Improvements (Post-MVP):**
1. **HTTP/1.1 Full Support:**
   - Keep-alive connections
   - Chunked transfer encoding
   - Compression (gzip)

2. **Caching:**
   - ETag support
   - Cache-Control headers
   - 304 Not Modified responses

3. **Advanced Features:**
   - WebSocket support (if needed for real-time updates)
   - HTTPS support (if security required)
   - Request logging for debugging

**Current Scope:** Minimal HTTP/1.0 implementation sufficient for Azgaar's needs.

---

## 9. Conclusion

The Azgaar serverless error is caused by a deliberate check in `main.js` that prevents execution via `file://` protocol. This check exists because Azgaar requires HTTP/HTTPS protocol for ES modules, Web Workers, and other modern web features.

**Recommended Solution:** Implement an embedded HTTP server in Godot using `TCPServer` to serve files from `user://azgaar/` on `http://127.0.0.1:PORT`. This solution:
- ✅ Eliminates external dependencies
- ✅ Works cross-platform
- ✅ Integrates with Godot lifecycle
- ✅ Provides full control over serving logic
- ✅ Minimal performance impact

**Next Steps:**
1. Implement `AzgaarServer.gd` with basic HTTP server functionality
2. Integrate with `AzgaarIntegrator` to provide HTTP URLs
3. Update `WorldBuilderAzgaar` to use HTTP URLs
4. Test thoroughly on all platforms
5. Monitor performance and optimize if needed

**Estimated Implementation Time:** 4-6 hours for MVP, 8-12 hours with full testing and polish.

---

## 10. References

- **Azgaar Main Script:** `tools/azgaar/main.js` (line 260-275)
- **Azgaar Wiki:** https://github.com/Azgaar/Fantasy-Map-Generator/wiki/Run-FMG-locally
- **Godot TCPServer Docs:** https://docs.godotengine.org/en/stable/classes/class_tcpserver.html
- **Godot StreamPeerTCP Docs:** https://docs.godotengine.org/en/stable/classes/class_streampeertcp.html
- **HTTP/1.1 Specification:** RFC 7230-7237
- **ES Modules & file:// Protocol:** HTML5 Specification, Module Loading

---

**End of Audit**

