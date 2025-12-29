// World Builder Alpine.js Data and IPC Handlers

// Override GodotBridge._handleUpdate for World Builder specific updates
// Note: This will be set after Alpine.js initializes
document.addEventListener('DOMContentLoaded', function() {
    var originalHandleUpdate = window.GodotBridge._handleUpdate;
    window.GodotBridge._handleUpdate = function(data) {
        if (data.update_type === 'params_update') {
            // Update parameters from Godot
            if (window.worldBuilderInstance) {
                Object.assign(window.worldBuilderInstance.params, data.params || {});
            }
        } else if (data.update_type === 'progress_update') {
            // Update progress bar
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.progressValue = data.progress || 0;
                window.worldBuilderInstance.statusText = data.status || '';
                window.worldBuilderInstance.isGenerating = data.is_generating || false;
            }
        } else if (data.update_type === 'step_definitions') {
            // Step definitions loaded
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.steps = data.steps || [];
            }
        } else if (data.update_type === 'archetypes') {
            // Archetypes loaded
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.archetypeNames = data.archetype_names || [];
            }
        } else if (data.update_type === 'archetype_params') {
            // Archetype preset parameters loaded
            if (window.worldBuilderInstance) {
                Object.assign(window.worldBuilderInstance.params, data.params || {});
            }
        }
        
        // Call original handler if needed
        if (originalHandleUpdate && typeof originalHandleUpdate === 'function') {
            originalHandleUpdate.call(this, data);
        }
    };
});

// Register the worldBuilder component before Alpine initializes (script loads synchronously)
document.addEventListener('alpine:init', () => {
    Alpine.data('worldBuilder', () => ({
        currentStep: 0,
        totalSteps: 8,
        steps: [],
        params: {},
        archetype: 'High Fantasy',
        archetypeNames: ['High Fantasy', 'Low Fantasy', 'Dark Fantasy', 'Realistic', 'Custom'],
        seed: Math.floor(Math.random() * 1e9),
        isGenerating: false,
        progressValue: 0,
        statusText: '',
        updateDebounceTimer: null,
        azgaarListenerInjected: false,
        
        init() {
            // Store instance for global access
            window.worldBuilderInstance = this;
            console.log('[WorldBuilder] Alpine.js init() called, steps:', this.steps.length);
            
            // Notify Godot that Alpine.js is ready via IPC
            if (window.GodotBridge && window.GodotBridge.postMessage) {
                window.GodotBridge.postMessage('alpine_ready', {});
                console.log('[WorldBuilder] Sent alpine_ready IPC message to Godot');
            } else {
                console.warn('[WorldBuilder] GodotBridge.postMessage not available - cannot notify Godot');
            }
            
            // Check if steps data was stored before Alpine initialized
            if (window._pendingStepsData && window._pendingStepsData.steps) {
                console.log('[WorldBuilder] Loading pending steps data:', window._pendingStepsData.steps.length);
                this.steps = window._pendingStepsData.steps;
                this._initializeParams();
                delete window._pendingStepsData;
            } else {
                // Request step definitions from Godot (fallback if direct injection fails)
                console.log('[WorldBuilder] Requesting step definitions from Godot');
                if (window.GodotBridge && window.GodotBridge.requestData) {
                    GodotBridge.requestData('step_definitions', (data) => {
                        if (data && data.steps) {
                            console.log('[WorldBuilder] Received steps via requestData:', data.steps.length);
                            this.steps = data.steps;
                            this._initializeParams();
                        }
                    });
                } else {
                    console.warn('[WorldBuilder] GodotBridge.requestData not available');
                }
            }
            
            // Fallback: Periodic check for late-arriving pending data (handles timing edge cases)
            if (this.steps.length === 0) {
                const checkInterval = setInterval(() => {
                    if (window._pendingStepsData && window._pendingStepsData.steps) {
                        console.log('[WorldBuilder] Late-loaded pending steps data:', window._pendingStepsData.steps.length);
                        this.steps = window._pendingStepsData.steps;
                        this._initializeParams();
                        delete window._pendingStepsData;
                        clearInterval(checkInterval);
                    } else if (this.steps.length > 0) {
                        // Steps were populated via another method (e.g., requestData callback)
                        clearInterval(checkInterval);
                    }
                }, 100);
                // Safety timeout: stop checking after 2 seconds
                setTimeout(() => {
                    clearInterval(checkInterval);
                    if (this.steps.length === 0) {
                        console.warn('[WorldBuilder] Steps still empty after 2 seconds - may need manual intervention');
                    }
                }, 2000);
            }
            
            // Request archetypes (already have names, but can request full data if needed)
            // Archetype names are already set in archetypeNames array
            
            // Send initial step
            this.setStep(0);
            console.log('[WorldBuilder] Initialized, current step:', this.currentStep, 'total steps:', this.steps.length);
            
            // Setup Azgaar iframe message listener injection
            this._setupAzgaarListener();
        },
    
    _setupAzgaarListener() {
        // Inject message listener into Azgaar iframe when it loads
        const iframe = document.getElementById('azgaar-iframe');
        if (!iframe) {
            console.warn('[WorldBuilder] Azgaar iframe not found, cannot setup listener');
            return;
        }
        
        const injectListener = (retryCount = 0) => {
            if (this.azgaarListenerInjected) {
                console.log('[WorldBuilder] Listener already injected, skipping');
                return; // Already injected
            }
            
            try {
                if (!iframe.contentWindow) {
                    console.warn('[WorldBuilder] iframe.contentWindow not available, retrying...');
                    if (retryCount < 10) {
                        setTimeout(() => injectListener(retryCount + 1), 500);
                    }
                    return;
                }
                
                // Check if we can access the iframe document (CORS check)
                let iframeDoc = null;
                try {
                    iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                } catch (e) {
                    console.warn('[WorldBuilder] Cannot access iframe document (CORS?), trying eval method:', e.message);
                    // If we can't access document, we can still try eval (if same-origin policy allows)
                }
                
                // Inject message listener script into Azgaar iframe
                const listenerScript = `
                    (function() {
                        // Check if listener already exists
                        if (window._azgaarMessageListenerInjected) {
                            console.log('[Azgaar] Listener already exists, skipping injection');
                            return;
                        }
                        window._azgaarMessageListenerInjected = true;
                        console.log('[Azgaar] Injecting message listener...');
                        
                        window.addEventListener('message', function(event) {
                            console.log('[Azgaar] Message received', {
                                type: event.data?.type,
                                origin: event.origin,
                                hasParams: !!event.data?.params,
                                hasSeed: event.data?.seed !== undefined
                            });
                            
                            // Accept messages from parent window (World Builder)
                            // Origin check: allow file://, res://, http://127.0.0.1, and * (for WebView contexts)
                            const allowedOrigins = ['file://', 'res://', 'http://127.0.0.1:8080', window.location.origin, '*'];
                            const isAllowedOrigin = allowedOrigins.some(origin => 
                                origin === '*' || event.origin === origin || event.origin.startsWith(origin)
                            );
                            
                            if (!isAllowedOrigin) {
                                console.warn('[Azgaar] Rejected message from origin:', event.origin);
                                return;
                            }
                            
                            // Handle azgaar_params message
                            if (event.data && event.data.type === 'azgaar_params') {
                                console.log('[Azgaar] Processing azgaar_params message');
                                if (typeof azgaar !== 'undefined' && azgaar.options) {
                                    try {
                                        // Apply parameters to azgaar.options
                                        if (event.data.params) {
                                            console.log('[Azgaar] Applying params:', Object.keys(event.data.params));
                                            Object.assign(azgaar.options, event.data.params);
                                        }
                                        // Set seed if provided
                                        if (event.data.seed !== undefined) {
                                            console.log('[Azgaar] Setting seed:', event.data.seed);
                                            azgaar.options.seed = event.data.seed;
                                        }
                                        console.log('[Azgaar] Parameters applied successfully');
                                    } catch (e) {
                                        console.error('[Azgaar] Error applying parameters:', e);
                                    }
                                } else {
                                    console.warn('[Azgaar] azgaar.options not available yet');
                                }
                            }
                            
                            // Handle azgaar_generate message
                            if (event.data && event.data.type === 'azgaar_generate') {
                                console.log('[Azgaar] Processing azgaar_generate message');
                                if (typeof azgaar !== 'undefined' && typeof azgaar.generate === 'function') {
                                    try {
                                        console.log('[Azgaar] Calling azgaar.generate()');
                                        azgaar.generate();
                                        console.log('[Azgaar] Generation triggered successfully');
                                    } catch (e) {
                                        console.error('[Azgaar] Error triggering generation:', e);
                                    }
                                } else {
                                    console.warn('[Azgaar] azgaar.generate not available yet');
                                }
                            }
                        });
                        
                        console.log('[Azgaar] Message listener injected successfully');
                    })();
                `;
                
                // Try to inject via script tag (more reliable than eval)
                if (iframeDoc) {
                    try {
                        const script = iframeDoc.createElement('script');
                        script.textContent = listenerScript;
                        iframeDoc.head.appendChild(script);
                        this.azgaarListenerInjected = true;
                        console.log('[WorldBuilder] Azgaar message listener injected via script tag');
                        return;
                    } catch (scriptError) {
                        console.warn('[WorldBuilder] Script tag injection failed, trying eval:', scriptError.message);
                    }
                }
                
                // Fallback to eval if script tag injection fails
                try {
                    iframe.contentWindow.eval(listenerScript);
                    this.azgaarListenerInjected = true;
                    console.log('[WorldBuilder] Azgaar message listener injected via eval');
                } catch (evalError) {
                    console.error('[WorldBuilder] Failed to inject listener via eval:', evalError);
                    // Retry if not too many attempts
                    if (retryCount < 10) {
                        console.log(`[WorldBuilder] Retrying listener injection (${retryCount + 1}/10)...`);
                        setTimeout(() => injectListener(retryCount + 1), 1000);
                    } else {
                        console.error('[WorldBuilder] Failed to inject listener after 10 retries');
                    }
                }
            } catch (e) {
                console.error('[WorldBuilder] Failed to inject Azgaar message listener:', e);
                if (retryCount < 10) {
                    setTimeout(() => injectListener(retryCount + 1), 1000);
                }
            }
        };
        
        // Try to inject immediately if iframe is already loaded
        if (iframe.contentDocument && iframe.contentDocument.readyState === 'complete') {
            // Wait for Azgaar to fully initialize (it loads many scripts)
            console.log('[WorldBuilder] Iframe already loaded, waiting for Azgaar initialization...');
            setTimeout(() => injectListener(), 3000);
        } else {
            // Wait for iframe to load
            console.log('[WorldBuilder] Waiting for iframe to load...');
            iframe.addEventListener('load', () => {
                console.log('[WorldBuilder] Iframe loaded, waiting for Azgaar initialization...');
                // Wait for Azgaar to initialize (it loads many scripts)
                setTimeout(() => injectListener(), 2000);
            }, { once: true });
        }
    },
    
    _initializeParams() {
        // Initialize params with default values from step definitions (only curated parameters)
        for (let step of this.steps) {
            if (step.parameters) {
                for (let param of step.parameters) {
                    // Only include curated parameters
                    if (param.curated !== false && !(param.azgaar_key in this.params)) {
                        this.params[param.azgaar_key] = param.default !== undefined ? param.default : 
                            (param.ui_type === 'CheckBox' ? false : 0);
                    }
                }
            }
        }
    },
    
    get currentStepTitle() {
        if (this.steps && this.steps[this.currentStep]) {
            return this.steps[this.currentStep].title || `Step ${this.currentStep + 1}`;
        }
        return `Step ${this.currentStep + 1}`;
    },
    
    get currentStepParams() {
        if (this.steps && this.steps.length > 0 && this.steps[this.currentStep]) {
            // Filter to only show curated parameters
            const allParams = this.steps[this.currentStep].parameters || [];
            const curatedParams = allParams.filter(param => param.curated !== false);
            console.log('[WorldBuilder] currentStepParams:', {
                step: this.currentStep,
                allParams: allParams.length,
                curatedParams: curatedParams.length
            });
            // Ensure params are initialized for displayed parameters
            for (let param of curatedParams) {
                if (!(param.azgaar_key in this.params)) {
                    // Initialize with default value
                    if (param.default !== undefined) {
                        this.params[param.azgaar_key] = param.default;
                    } else if (param.ui_type === 'CheckBox') {
                        this.params[param.azgaar_key] = false;
                    } else if (param.ui_type === 'HSlider' || param.ui_type === 'SpinBox') {
                        this.params[param.azgaar_key] = param.min || 0;
                    }
                }
            }
            return curatedParams;
        }
        console.warn('[WorldBuilder] currentStepParams: no steps available', {
            hasSteps: !!this.steps,
            stepsLength: this.steps ? this.steps.length : 0,
            currentStep: this.currentStep
        });
        return [];
    },
    
    get currentStepInfoText() {
        if (this.steps && this.steps[this.currentStep]) {
            return this.steps[this.currentStep].info_text || null;
        }
        return null;
    },
    
    setStep(index) {
        if (index >= 0 && index < this.totalSteps) {
            this.currentStep = index;
            // Send step change to Godot
            GodotBridge.postMessage('set_step', { step: index });
            // Ensure params are initialized for this step
            this._ensureStepParamsInitialized(index);
        }
    },
    
    _ensureStepParamsInitialized(stepIndex) {
        // Initialize any missing params for the current step with defaults
        if (this.steps && this.steps[stepIndex] && this.steps[stepIndex].parameters) {
            for (let param of this.steps[stepIndex].parameters) {
                // Only initialize curated parameters
                if (param.curated !== false && !(param.azgaar_key in this.params)) {
                    // Use default if available, otherwise use type-appropriate default
                    if (param.default !== undefined) {
                        this.params[param.azgaar_key] = param.default;
                    } else if (param.ui_type === 'CheckBox') {
                        this.params[param.azgaar_key] = false;
                    } else if (param.ui_type === 'HSlider' || param.ui_type === 'SpinBox') {
                        this.params[param.azgaar_key] = param.min || 0;
                    }
                }
            }
        }
    },
    
    previousStep() {
        if (this.currentStep > 0) {
            this.setStep(this.currentStep - 1);
        }
    },
    
    nextStep() {
        if (this.currentStep < this.totalSteps - 1) {
            this.setStep(this.currentStep + 1);
        }
    },
    
    loadArchetype(archetypeName) {
        this.archetype = archetypeName;
        GodotBridge.postMessage('load_archetype', { archetype: archetypeName });
    },
    
    setSeed(newSeed) {
        this.seed = newSeed;
        GodotBridge.postMessage('set_seed', { seed: this.seed });
    },
    
    randomizeSeed() {
        this.seed = Math.floor(Math.random() * 1e9);
        this.setSeed(this.seed);
    },
    
    updateParam(key, value) {
        // Find the parameter definition to get clamping info
        let paramDef = null;
        for (let step of this.steps) {
            if (step.parameters) {
                paramDef = step.parameters.find(p => p.azgaar_key === key);
                if (paramDef) break;
            }
        }
        
        // Clamp value if param definition exists and has min/max
        if (paramDef && typeof value === 'number') {
            const min = paramDef.clamped_min !== undefined ? paramDef.clamped_min : paramDef.min;
            const max = paramDef.clamped_max !== undefined ? paramDef.clamped_max : paramDef.max;
            if (min !== undefined && max !== undefined) {
                value = Math.max(min, Math.min(max, value));
            }
            // Also handle step for sliders
            if (paramDef.step !== undefined) {
                // Round to nearest step
                value = Math.round(value / paramDef.step) * paramDef.step;
            }
        }
        
        // Update local params immediately (for UI responsiveness)
        this.params[key] = value;
        
        // Debounce sending to Godot (100ms delay)
        if (this.updateDebounceTimer) {
            clearTimeout(this.updateDebounceTimer);
        }
        this.updateDebounceTimer = setTimeout(() => {
            // Send to Godot (server-side will also clamp)
            GodotBridge.postMessage('update_param', { 
                azgaar_key: key, 
                value: this.params[key]
            });
            this.updateDebounceTimer = null;
        }, 100);
    },
    
    generate() {
        console.log('[WorldBuilder] generate() called', {
            params: this.params,
            seed: this.seed,
            listenerInjected: this.azgaarListenerInjected
        });
        
        this.isGenerating = true;
        this.progressValue = 0;
        this.statusText = 'Generating...';
        
        // Send to Godot for progress tracking
        GodotBridge.postMessage('generate', { params: this.params });
        console.log('[WorldBuilder] Sent generate IPC message to Godot');
        
        // Ensure message listener is injected before sending messages
        if (!this.azgaarListenerInjected) {
            console.log('[WorldBuilder] Listener not injected, setting up...');
            this._setupAzgaarListener();
        }
        
        // Send parameters to Azgaar iframe via postMessage
        const iframe = document.getElementById('azgaar-iframe');
        if (!iframe || !iframe.contentWindow) {
            console.error('[WorldBuilder] Iframe not found or has no contentWindow');
            this.isGenerating = false;
            this.statusText = 'Error: Azgaar iframe not available';
            return;
        }
        
        try {
            // Wait for iframe to be ready, then send parameters
            const sendToIframe = () => {
                if (!iframe.contentWindow) {
                    console.warn('[WorldBuilder] iframe.contentWindow is null');
                    this.isGenerating = false;
                    this.statusText = 'Error: Cannot access Azgaar iframe';
                    return;
                }
                
                // Check if azgaar is ready before sending messages
                const checkAndSend = (retryCount = 0) => {
                    const maxRetries = 10;
                    const retryDelay = 500;
                    
                    try {
                        // Check if azgaar is available in iframe
                        const iframeWindow = iframe.contentWindow;
                        const hasAzgaar = iframeWindow && typeof iframeWindow.azgaar !== 'undefined';
                        const hasOptions = hasAzgaar && iframeWindow.azgaar.options;
                        const hasGenerate = hasAzgaar && typeof iframeWindow.azgaar.generate === 'function';
                        
                        console.log('[WorldBuilder] Checking Azgaar readiness', {
                            hasAzgaar,
                            hasOptions,
                            hasGenerate,
                            retryCount
                        });
                        
                        if (!hasAzgaar || !hasOptions || !hasGenerate) {
                            if (retryCount < maxRetries) {
                                console.log(`[WorldBuilder] Azgaar not ready, retrying in ${retryDelay}ms (${retryCount + 1}/${maxRetries})`);
                                setTimeout(() => checkAndSend(retryCount + 1), retryDelay);
                                return;
                            } else {
                                console.warn('[WorldBuilder] Azgaar not ready after max retries, sending anyway');
                            }
                        }
                        
                        // Ensure listener is injected (retry if needed)
                        if (!this.azgaarListenerInjected) {
                            console.log('[WorldBuilder] Injecting listener before sending messages');
                            try {
                                const listenerScript = `
                                    (function() {
                                        if (window._azgaarMessageListenerInjected) {
                                            console.log('[Azgaar] Listener already injected');
                                            return;
                                        }
                                        window._azgaarMessageListenerInjected = true;
                                        console.log('[Azgaar] Injecting message listener');
                                        window.addEventListener('message', function(event) {
                                            console.log('[Azgaar] Message received', {
                                                type: event.data?.type,
                                                origin: event.origin,
                                                hasParams: !!event.data?.params,
                                                hasSeed: event.data?.seed !== undefined
                                            });
                                            
                                            const allowedOrigins = ['file://', 'res://', 'http://127.0.0.1:8080', window.location.origin, '*'];
                                            const isAllowedOrigin = allowedOrigins.some(origin => 
                                                origin === '*' || event.origin === origin || event.origin.startsWith(origin)
                                            );
                                            
                                            if (!isAllowedOrigin) {
                                                console.warn('[Azgaar] Rejected message from origin:', event.origin);
                                                return;
                                            }
                                            
                                            if (event.data && event.data.type === 'azgaar_params') {
                                                console.log('[Azgaar] Processing azgaar_params message');
                                                if (typeof azgaar !== 'undefined' && azgaar.options) {
                                                    try {
                                                        if (event.data.params) {
                                                            console.log('[Azgaar] Applying params:', Object.keys(event.data.params));
                                                            Object.assign(azgaar.options, event.data.params);
                                                        }
                                                        if (event.data.seed !== undefined) {
                                                            console.log('[Azgaar] Setting seed:', event.data.seed);
                                                            azgaar.options.seed = event.data.seed;
                                                        }
                                                        console.log('[Azgaar] Parameters applied successfully');
                                                    } catch (e) {
                                                        console.error('[Azgaar] Error applying parameters:', e);
                                                    }
                                                } else {
                                                    console.warn('[Azgaar] azgaar.options not available yet');
                                                }
                                            }
                                            
                                            if (event.data && event.data.type === 'azgaar_generate') {
                                                console.log('[Azgaar] Processing azgaar_generate message');
                                                if (typeof azgaar !== 'undefined' && typeof azgaar.generate === 'function') {
                                                    try {
                                                        console.log('[Azgaar] Calling azgaar.generate()');
                                                        azgaar.generate();
                                                        console.log('[Azgaar] Generation triggered successfully');
                                                    } catch (e) {
                                                        console.error('[Azgaar] Error triggering generation:', e);
                                                    }
                                                } else {
                                                    console.warn('[Azgaar] azgaar.generate not available yet');
                                                }
                                            }
                                        });
                                        console.log('[Azgaar] Message listener injected successfully');
                                    })();
                                `;
                                // Try script tag first, then eval
                                try {
                                    const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                                    if (iframeDoc) {
                                        const script = iframeDoc.createElement('script');
                                        script.textContent = listenerScript;
                                        iframeDoc.head.appendChild(script);
                                        this.azgaarListenerInjected = true;
                                        console.log('[WorldBuilder] Listener injected via script tag');
                                    } else {
                                        iframe.contentWindow.eval(listenerScript);
                                        this.azgaarListenerInjected = true;
                                        console.log('[WorldBuilder] Listener injected via eval');
                                    }
                                } catch (e) {
                                    iframe.contentWindow.eval(listenerScript);
                                    this.azgaarListenerInjected = true;
                                    console.log('[WorldBuilder] Listener injected via eval (fallback)');
                                }
                            } catch (e) {
                                console.warn('[WorldBuilder] Failed to inject listener on send:', e);
                            }
                        }
                        
                        // Send parameters to Azgaar iframe
                        const paramsMessage = {
                            type: 'azgaar_params',
                            params: this.params,
                            seed: this.seed
                        };
                        
                        // Trigger generation in Azgaar
                        const generateMessage = {
                            type: 'azgaar_generate'
                        };
                        
                        console.log('[WorldBuilder] Sending messages to Azgaar iframe', {
                            paramsMessage,
                            generateMessage,
                            targetOrigin: '*'
                        });
                        
                        // Use '*' as targetOrigin since we're in a WebView context (res:// origin)
                        // The listener will validate the origin
                        try {
                            iframe.contentWindow.postMessage(paramsMessage, '*');
                            console.log('[WorldBuilder] Sent azgaar_params message');
                            
                            // Small delay between params and generate to ensure params are applied
                            setTimeout(() => {
                                iframe.contentWindow.postMessage(generateMessage, '*');
                                console.log('[WorldBuilder] Sent azgaar_generate message');
                            }, 100);
                        } catch (postError) {
                            console.error('[WorldBuilder] Error sending postMessage:', postError);
                            this.isGenerating = false;
                            this.statusText = 'Error: Failed to send message to Azgaar';
                        }
                    } catch (e) {
                        console.error('[WorldBuilder] Error in checkAndSend:', e);
                        this.isGenerating = false;
                        this.statusText = 'Error: Failed to communicate with Azgaar';
                    }
                };
                
                // Start checking and sending
                checkAndSend();
            };
            
            // Try immediately, or wait for iframe load
            if (iframe.contentDocument && iframe.contentDocument.readyState === 'complete') {
                console.log('[WorldBuilder] Iframe already loaded, sending immediately');
                sendToIframe();
            } else {
                console.log('[WorldBuilder] Waiting for iframe to load');
                iframe.addEventListener('load', sendToIframe, { once: true });
            }
        } catch (e) {
            console.error('[WorldBuilder] Failed to send to iframe:', e);
            this.isGenerating = false;
            this.statusText = 'Error: Failed to communicate with Azgaar';
        }
    }
    }));
});

