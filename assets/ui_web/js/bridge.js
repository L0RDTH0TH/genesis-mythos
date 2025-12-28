// Godot Bridge API - Shared communication library for WebView UIs
// Provides bidirectional communication between JavaScript and Godot via godot_wry IPC

// Initialize GodotBridge namespace
window.GodotBridge = {
    // Send message to Godot
    postMessage: function(type, data) {
        // Support both object format {type, data} and separate parameters
        if (typeof type === 'object' && type !== null) {
            // Single object parameter format
            data = type;
            type = data.type || 'message';
        }
        
        // Build message object
        var message = {
            type: type,
            data: data || {},
            timestamp: Date.now()
        };
        
        // godot_wry provides window.ipc.postMessage directly (see character_creator example)
        if (window.ipc && typeof window.ipc.postMessage === 'function') {
            window.ipc.postMessage(JSON.stringify(message));
        } else {
            console.warn('Godot IPC not available - message not sent:', message);
        }
    },
    
    // Request data from Godot (async)
    requestData: function(endpoint, callback) {
        var requestId = Math.random().toString(36).substring(2, 15);
        window.GodotBridge._pendingRequests[requestId] = callback;
        window.GodotBridge.postMessage('request_data', {
            request_id: requestId,
            endpoint: endpoint
        });
    },
    
    // Call Godot function (async)
    callFunction: function(functionName, args, callback) {
        var requestId = Math.random().toString(36).substring(2, 15);
        window.GodotBridge._pendingRequests[requestId] = callback;
        window.GodotBridge.postMessage('call_function', {
            request_id: requestId,
            function_name: functionName,
            arguments: args || []
        });
    },
    
    // Handle update messages from Godot
    _handleUpdate: function(data) {
        // Override this in specific UI scripts to handle updates
        console.log('Godot update received:', data);
    },
    
    // Pending request callbacks
    _pendingRequests: {}
};

// Handle messages from Godot (responses to requests)
if (typeof window.addEventListener !== 'undefined') {
    window.addEventListener('message', function(event) {
        if (event.data && typeof event.data === 'string') {
            try {
                var message = JSON.parse(event.data);
                if (message.type === 'response' && message.request_id) {
                    var callback = window.GodotBridge._pendingRequests[message.request_id];
                    if (callback) {
                        callback(message.data);
                        delete window.GodotBridge._pendingRequests[message.request_id];
                    }
                } else if (message.type === 'update') {
                    // Handle push updates from Godot
                    window.GodotBridge._handleUpdate(message.data);
                }
            } catch (e) {
                console.error('Failed to parse message from Godot:', e);
            }
        }
    });
}

