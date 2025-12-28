// MainMenu Web UI - JavaScript handlers for button clicks and viewport resize

// Wait for DOM and bridge to be ready
document.addEventListener('DOMContentLoaded', function() {
    // Ensure bridge is loaded
    if (typeof GodotBridge === 'undefined') {
        console.error('GodotBridge not found! Make sure bridge.js is loaded.');
        return;
    }
    
    // Initialize IPC connection check (godot_wry provides window.ipc automatically)
    if (typeof window.ipc === 'undefined') {
        console.warn('Godot IPC not available - window.ipc should be provided by godot_wry');
    }
    
    // Get button elements
    var createCharacterBtn = document.getElementById('create-character-btn');
    var createWorldBtn = document.getElementById('create-world-btn');
    
    if (!createCharacterBtn || !createWorldBtn) {
        console.error('Button elements not found!');
        return;
    }
    
    // Character Creation button handler
    createCharacterBtn.addEventListener('click', function() {
        console.log('Character Creation button clicked');
        GodotBridge.postMessage('navigate', {
            scene_path: 'res://scenes/character_creation/CharacterCreationRoot.tscn'
        });
    });
    
    // World Creation button handler
    createWorldBtn.addEventListener('click', function() {
        console.log('World Creation button clicked');
        GodotBridge.postMessage('navigate', {
            scene_path: 'res://ui/world_builder/WorldBuilderWeb.tscn'
        });
    });
    
    // Viewport resize handler
    var resizeTimeout = null;
    window.addEventListener('resize', function() {
        // Throttle resize events
        if (resizeTimeout) {
            clearTimeout(resizeTimeout);
        }
        resizeTimeout = setTimeout(function() {
            GodotBridge.postMessage('viewport_resize', {
                width: window.innerWidth,
                height: window.innerHeight
            });
        }, 100);
    });
    
    // Send initial viewport size
    setTimeout(function() {
        GodotBridge.postMessage('viewport_resize', {
            width: window.innerWidth,
            height: window.innerHeight
        });
    }, 100);
    
    console.log('MainMenu Web UI initialized');
});

