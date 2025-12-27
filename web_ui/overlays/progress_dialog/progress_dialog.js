// Progress Dialog Alpine.js Data and IPC Handlers

// Alpine.js data component for progress dialog
Alpine.data('progressDialog', function() {
    return {
        title: '',
        status: '',
        progress: 0,
        visible: false,
        
        init() {
            // Override GodotBridge._handleUpdate to handle progress updates
            var self = this;
            var originalHandleUpdate = window.GodotBridge._handleUpdate;
            
            window.GodotBridge._handleUpdate = function(data) {
                if (data.type === 'show_progress') {
                    self.visible = true;
                    self.title = data.title || 'Processing...';
                    self.status = data.status || 'Please wait...';
                    self.progress = data.progress || 0;
                } else if (data.type === 'update_progress') {
                    self.progress = data.progress !== undefined ? data.progress : self.progress;
                    if (data.status !== undefined) {
                        self.status = data.status;
                    }
                } else if (data.type === 'hide_progress') {
                    self.visible = false;
                    // Reset values after transition
                    setTimeout(function() {
                        self.title = '';
                        self.status = '';
                        self.progress = 0;
                    }, 200);
                }
                
                // Call original handler if needed
                if (originalHandleUpdate && typeof originalHandleUpdate === 'function') {
                    originalHandleUpdate.call(this, data);
                }
            };
        },
        
        handleBackdropClick() {
            // Progress dialogs are non-cancellable - do nothing on backdrop click
            // This maintains the modal blocking behavior
        }
    };
});

