// ╔═══════════════════════════════════════════════════════════
// ║ bridge.js
// ║ Desc: Godot-WebView IPC bridge for bidirectional communication
// ║ Author: Lordthoth
// ╚═══════════════════════════════════════════════════════════

// GodotBridge - Communication bridge between Godot and WebView
// Works with godot_wry's IPC system via postMessage and ipc_message signal
(function() {
    'use strict';
    
    // Initialize Godot bridge object
    if (typeof window.GodotBridge === 'undefined') {
        window.GodotBridge = {
            // Send message to Godot via godot_wry IPC
            postMessage: function(type, data) {
                var message = {
                    type: type,
                    data: data || {},
                    timestamp: Date.now()
                };
                
                try {
                    // godot_wry exposes postMessage via window.godot.postMessage or direct IPC
                    if (typeof window.godot !== 'undefined' && window.godot.postMessage) {
                        window.godot.postMessage(JSON.stringify(message));
                        console.log('[GodotBridge] Message sent via window.godot.postMessage:', type, data);
                    } else if (typeof window.ipc !== 'undefined' && window.ipc.postMessage) {
                        window.ipc.postMessage(JSON.stringify(message));
                        console.log('[GodotBridge] Message sent via window.ipc.postMessage:', type, data);
                    } else {
                        console.warn('[GodotBridge] IPC not available, message not sent:', type, data);
                    }
                } catch (error) {
                    console.error('[GodotBridge] Error sending message:', error);
                }
            },
            
            // Receive message from Godot (called by godot_wry via injected script)
            onMessage: function(message) {
                try {
                    var data = typeof message === 'string' ? JSON.parse(message) : message;
                    console.log('[GodotBridge] Message received:', data);
                    
                    // Dispatch custom event
                    var event = new CustomEvent('godot-message', {
                        detail: data
                    });
                    window.dispatchEvent(event);
                } catch (error) {
                    console.error('[GodotBridge] Error parsing message:', error);
                }
            }
        };
        
        // Expose onMessage globally for godot_wry to call
        window.godotBridgeOnMessage = function(message) {
            window.GodotBridge.onMessage(message);
        };
        
        console.log('[GodotBridge] Bridge loaded');
    }
})();

