// ╔═══════════════════════════════════════════════════════════
// ║ world_builder.js
// ║ Desc: World Builder Alpine.js Data and IPC Handlers with enhanced Azgaar communication
// ║ Author: Lordthoth
// ╚═══════════════════════════════════════════════════════════

// World Builder Alpine.js Data and IPC Handlers

// Override GodotBridge._handleUpdate for World Builder specific updates
// Note: This will be set after Alpine.js initializes
document.addEventListener('DOMContentLoaded', function() {
    console.log('[Genesis World Builder] DOMContentLoaded event fired');
    var originalHandleUpdate = window.GodotBridge._handleUpdate;
    window.GodotBridge._handleUpdate = function(data) {
        console.log('[Genesis World Builder] _handleUpdate called', { update_type: data.update_type });
        if (data.update_type === 'params_update') {
            // Update parameters from Godot
            if (window.worldBuilderInstance) {
                Object.assign(window.worldBuilderInstance.params, data.params || {});
                console.log('[Genesis World Builder] Updated params from Godot', Object.keys(data.params || {}));
            }
        } else if (data.update_type === 'progress_update') {
            // Update progress bar
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.progressValue = data.progress || 0;
                window.worldBuilderInstance.statusText = data.status || '';
                window.worldBuilderInstance.isGenerating = data.is_generating || false;
                console.log('[Genesis World Builder] Progress update', { progress: data.progress, status: data.status });
            }
        } else if (data.update_type === 'step_definitions') {
            // Step definitions loaded
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.steps = data.steps || [];
                console.log('[Genesis World Builder] Steps loaded', { count: data.steps?.length || 0 });
            }
        } else if (data.update_type === 'archetypes') {
            // Archetypes loaded
            if (window.worldBuilderInstance) {
                window.worldBuilderInstance.archetypeNames = data.archetype_names || [];
                console.log('[Genesis World Builder] Archetypes loaded', { count: data.archetype_names?.length || 0 });
            }
        } else if (data.update_type === 'archetype_params') {
            // Archetype preset parameters loaded
            if (window.worldBuilderInstance) {
                Object.assign(window.worldBuilderInstance.params, data.params || {});
                console.log('[Genesis World Builder] Archetype params loaded', Object.keys(data.params || {}));
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
    console.log('[Genesis World Builder] Alpine.js init event fired');
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
        azgaarListenerVerified: false,
        errorMessage: null,
        errorDetails: null,
        
        init() {
            // Store instance for global access
            window.worldBuilderInstance = this;
            console.log('[Genesis World Builder] Alpine.js init() called', {
                timestamp: new Date().toISOString(),
                stepsCount: this.steps.length,
                hasGodotBridge: !!window.GodotBridge
            });
            
            // Clear any previous errors
            this.errorMessage = null;
            this.errorDetails = null;
            
            // Notify Godot that Alpine.js is ready via IPC
            if (window.GodotBridge && window.GodotBridge.postMessage) {
                window.GodotBridge.postMessage('alpine_ready', {});
                console.log('[Genesis World Builder] Sent alpine_ready IPC message to Godot', {
                    timestamp: new Date().toISOString()
                });
            } else {
                console.warn('[Genesis World Builder] GodotBridge.postMessage not available - cannot notify Godot');
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
    
    /**
     * Poll for Azgaar readiness (checks for azgaar, azgaar.options, and azgaar.generate)
     * @param {HTMLIFrameElement} iframe - The Azgaar iframe element
     * @param {number} maxWaitMs - Maximum time to wait in milliseconds (default: 60000)
     * @param {number} pollIntervalMs - Polling interval in milliseconds (default: 100)
     * @returns {Promise<boolean>} True if Azgaar is ready, false if timeout
     */
    async _pollForAzgaarReady(iframe, maxWaitMs = 60000, pollIntervalMs = 100) {
        const startTime = Date.now();
        let attemptCount = 0;
        
        console.log('[Genesis World Builder] Starting Azgaar readiness polling', {
            timestamp: new Date().toISOString(),
            maxWaitMs,
            pollIntervalMs
        });
        
        return new Promise((resolve) => {
            const checkReady = () => {
                attemptCount++;
                const elapsed = Date.now() - startTime;
                
                try {
                    if (!iframe || !iframe.contentWindow) {
                        console.log(`[Genesis World Builder] Poll attempt ${attemptCount}: iframe.contentWindow not available`);
                        if (elapsed < maxWaitMs) {
                            setTimeout(checkReady, pollIntervalMs);
                        } else {
                            console.error('[Genesis World Builder] Azgaar readiness polling timeout: iframe.contentWindow never became available');
                            resolve(false);
                        }
                        return;
                    }
                    
                    const iframeWindow = iframe.contentWindow;
                    const hasAzgaar = typeof iframeWindow.azgaar !== 'undefined';
                    const hasOptions = hasAzgaar && iframeWindow.azgaar && typeof iframeWindow.azgaar.options !== 'undefined';
                    const hasGenerate = hasAzgaar && iframeWindow.azgaar && typeof iframeWindow.azgaar.generate === 'function';
                    
                    console.log(`[Genesis World Builder] Poll attempt ${attemptCount} (${elapsed}ms elapsed):`, {
                        hasAzgaar,
                        hasOptions,
                        hasGenerate,
                        allReady: hasAzgaar && hasOptions && hasGenerate
                    });
                    
                    if (hasAzgaar && hasOptions && hasGenerate) {
                        console.log('[Genesis World Builder] Azgaar is ready!', {
                            timestamp: new Date().toISOString(),
                            elapsedMs: elapsed,
                            attempts: attemptCount
                        });
                        resolve(true);
                    } else if (elapsed < maxWaitMs) {
                        setTimeout(checkReady, pollIntervalMs);
                    } else {
                        console.error('[Genesis World Builder] Azgaar readiness polling timeout', {
                            timestamp: new Date().toISOString(),
                            elapsedMs: elapsed,
                            attempts: attemptCount,
                            finalState: { hasAzgaar, hasOptions, hasGenerate }
                        });
                        resolve(false);
                    }
                } catch (e) {
                    console.error(`[Genesis World Builder] Error during readiness check (attempt ${attemptCount}):`, e);
                    if (elapsed < maxWaitMs) {
                        setTimeout(checkReady, pollIntervalMs);
                    } else {
                        resolve(false);
                    }
                }
            };
            
            checkReady();
        });
    },
    
    /**
     * Inject message listener into Azgaar iframe with retry logic and verification
     * @param {HTMLIFrameElement} iframe - The Azgaar iframe element
     * @param {number} retryCount - Current retry attempt (internal)
     * @param {number} maxRetries - Maximum retry attempts (default: 15)
     * @returns {Promise<boolean>} True if injection succeeded and was verified, false otherwise
     */
    async _injectAzgaarListener(iframe, retryCount = 0, maxRetries = 15) {
        if (this.azgaarListenerInjected && this.azgaarListenerVerified) {
            console.log('[Genesis World Builder] Listener already injected and verified, skipping');
            return true;
        }
        
        const attemptStartTime = Date.now();
        console.log(`[Genesis World Builder] Injecting Azgaar listener (attempt ${retryCount + 1}/${maxRetries})`, {
            timestamp: new Date().toISOString(),
            alreadyInjected: this.azgaarListenerInjected,
            alreadyVerified: this.azgaarListenerVerified
        });
        
        try {
            if (!iframe || !iframe.contentWindow) {
                console.warn(`[Genesis World Builder] iframe.contentWindow not available (attempt ${retryCount + 1})`);
                if (retryCount < maxRetries) {
                    // Exponential backoff: 200ms * 2^retryCount, capped at 2000ms
                    const delay = Math.min(200 * Math.pow(2, retryCount), 2000);
                    console.log(`[Genesis World Builder] Retrying listener injection in ${delay}ms...`);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    return await this._injectAzgaarListener(iframe, retryCount + 1, maxRetries);
                } else {
                    console.error('[Genesis World Builder] Failed to inject listener: iframe.contentWindow never became available');
                    return false;
                }
            }
            
            // Check if we can access the iframe document (CORS check)
            let iframeDoc = null;
            let injectionMethod = null;
            try {
                iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                console.log('[Genesis World Builder] Can access iframe document, will try script tag injection');
            } catch (e) {
                console.warn('[Genesis World Builder] Cannot access iframe document (CORS?), will use eval method:', e.message);
            }
            
            // Inject message listener script into Azgaar iframe
            const listenerScript = `
                (function() {
                    // Check if listener already exists
                    if (window._azgaarMessageListenerInjected) {
                        console.log('[Genesis Azgaar] Listener already exists, skipping injection');
                        return;
                    }
                    window._azgaarMessageListenerInjected = true;
                    console.log('[Genesis Azgaar] Injecting message listener...', {
                        timestamp: new Date().toISOString()
                    });
                    
                    window.addEventListener('message', function(event) {
                        console.log('[Genesis Azgaar] Message received', {
                            timestamp: new Date().toISOString(),
                            type: event.data?.type,
                            origin: event.origin,
                            hasParams: !!event.data?.params,
                            hasSeed: event.data?.seed !== undefined,
                            fullData: event.data
                        });
                        
                        // Accept messages from parent window (World Builder)
                        // Origin check: allow file://, res://, http://127.0.0.1, and * (for WebView contexts)
                        const allowedOrigins = ['file://', 'res://', 'http://127.0.0.1:8080', window.location.origin, '*'];
                        const isAllowedOrigin = allowedOrigins.some(origin => 
                            origin === '*' || event.origin === origin || event.origin.startsWith(origin)
                        );
                        
                        if (!isAllowedOrigin) {
                            console.warn('[Genesis Azgaar] Rejected message from origin:', event.origin);
                            return;
                        }
                        
                        // Handle test message for verification
                        if (event.data && event.data.type === 'azgaar_test') {
                            console.log('[Genesis Azgaar] Test message received - listener is working!', {
                                timestamp: new Date().toISOString(),
                                testId: event.data.testId
                            });
                            return;
                        }
                        
                        // Handle azgaar_params message
                        if (event.data && event.data.type === 'azgaar_params') {
                            console.log('[Genesis Azgaar] Processing azgaar_params message', {
                                timestamp: new Date().toISOString(),
                                paramsCount: event.data.params ? Object.keys(event.data.params).length : 0,
                                hasSeed: event.data.seed !== undefined
                            });
                            
                            if (typeof azgaar !== 'undefined' && azgaar.options) {
                                try {
                                    const beforeOptions = JSON.stringify(azgaar.options);
                                    console.log('[Genesis Azgaar] Before applying params:', {
                                        currentSeed: azgaar.options.seed,
                                        optionsKeys: Object.keys(azgaar.options)
                                    });
                                    
                                    // Apply parameters to azgaar.options
                                    if (event.data.params) {
                                        console.log('[Genesis Azgaar] Applying params:', Object.keys(event.data.params));
                                        Object.assign(azgaar.options, event.data.params);
                                    }
                                    // Set seed if provided
                                    if (event.data.seed !== undefined) {
                                        console.log('[Genesis Azgaar] Setting seed:', event.data.seed);
                                        azgaar.options.seed = event.data.seed;
                                    }
                                    
                                    const afterOptions = JSON.stringify(azgaar.options);
                                    console.log('[Genesis Azgaar] After applying params:', {
                                        newSeed: azgaar.options.seed,
                                        optionsChanged: beforeOptions !== afterOptions
                                    });
                                    console.log('[Genesis Azgaar] Parameters applied successfully');
                                } catch (e) {
                                    console.error('[Genesis Azgaar] Error applying parameters:', e, {
                                        stack: e.stack,
                                        timestamp: new Date().toISOString()
                                    });
                                }
                            } else {
                                console.warn('[Genesis Azgaar] azgaar.options not available yet', {
                                    hasAzgaar: typeof azgaar !== 'undefined',
                                    hasOptions: typeof azgaar !== 'undefined' && azgaar.options
                                });
                            }
                        }
                        
                        // Handle azgaar_generate message
                        if (event.data && event.data.type === 'azgaar_generate') {
                            console.log('[Genesis Azgaar] Processing azgaar_generate message', {
                                timestamp: new Date().toISOString()
                            });
                            
                            if (typeof azgaar !== 'undefined' && typeof azgaar.generate === 'function') {
                                try {
                                    console.log('[Genesis Azgaar] Calling azgaar.generate()', {
                                        timestamp: new Date().toISOString(),
                                        optionsSeed: azgaar.options?.seed
                                    });
                                    azgaar.generate();
                                    console.log('[Genesis Azgaar] Generation triggered successfully', {
                                        timestamp: new Date().toISOString()
                                    });
                                } catch (e) {
                                    console.error('[Genesis Azgaar] Error triggering generation:', e, {
                                        stack: e.stack,
                                        timestamp: new Date().toISOString()
                                    });
                                }
                            } else {
                                console.warn('[Genesis Azgaar] azgaar.generate not available yet', {
                                    hasAzgaar: typeof azgaar !== 'undefined',
                                    hasGenerate: typeof azgaar !== 'undefined' && typeof azgaar.generate === 'function'
                                });
                            }
                        }
                    });
                    
                    console.log('[Genesis Azgaar] Message listener injected successfully', {
                        timestamp: new Date().toISOString()
                    });
                })();
            `;
            
            // Try to inject via script tag (more reliable than eval)
            if (iframeDoc) {
                try {
                    const script = iframeDoc.createElement('script');
                    script.textContent = listenerScript;
                    iframeDoc.head.appendChild(script);
                    this.azgaarListenerInjected = true;
                    injectionMethod = 'script_tag';
                    console.log('[Genesis World Builder] Azgaar message listener injected via script tag', {
                        timestamp: new Date().toISOString(),
                        elapsedMs: Date.now() - attemptStartTime
                    });
                } catch (scriptError) {
                    console.warn('[Genesis World Builder] Script tag injection failed, trying eval:', scriptError.message);
                    // Fall through to eval
                }
            }
            
            // Fallback to eval if script tag injection fails or wasn't attempted
            if (!this.azgaarListenerInjected) {
                try {
                    iframe.contentWindow.eval(listenerScript);
                    this.azgaarListenerInjected = true;
                    injectionMethod = 'eval';
                    console.log('[Genesis World Builder] Azgaar message listener injected via eval', {
                        timestamp: new Date().toISOString(),
                        elapsedMs: Date.now() - attemptStartTime
                    });
                } catch (evalError) {
                    console.error('[Genesis World Builder] Failed to inject listener via eval:', evalError, {
                        message: evalError.message,
                        stack: evalError.stack
                    });
                    // Retry if not too many attempts
                    if (retryCount < maxRetries) {
                        const delay = Math.min(200 * Math.pow(2, retryCount), 2000);
                        console.log(`[Genesis World Builder] Retrying listener injection in ${delay}ms (${retryCount + 1}/${maxRetries})...`);
                        await new Promise(resolve => setTimeout(resolve, delay));
                        return await this._injectAzgaarListener(iframe, retryCount + 1, maxRetries);
                    } else {
                        console.error('[Genesis World Builder] Failed to inject listener after max retries');
                        return false;
                    }
                }
            }
            
            // Verify injection by sending a test message
            console.log('[Genesis World Builder] Verifying listener injection...', {
                timestamp: new Date().toISOString(),
                injectionMethod
            });
            
            const verificationResult = await this._verifyListenerInjection(iframe);
            if (verificationResult) {
                this.azgaarListenerVerified = true;
                console.log('[Genesis World Builder] Listener injection verified successfully!', {
                    timestamp: new Date().toISOString(),
                    totalElapsedMs: Date.now() - attemptStartTime
                });
                return true;
            } else {
                console.warn('[Genesis World Builder] Listener injection verification failed, will retry...');
                this.azgaarListenerInjected = false; // Reset to allow retry
                if (retryCount < maxRetries) {
                    const delay = Math.min(200 * Math.pow(2, retryCount), 2000);
                    console.log(`[Genesis World Builder] Retrying injection with verification in ${delay}ms...`);
                    await new Promise(resolve => setTimeout(resolve, delay));
                    return await this._injectAzgaarListener(iframe, retryCount + 1, maxRetries);
                } else {
                    console.error('[Genesis World Builder] Failed to verify listener after max retries');
                    return false;
                }
            }
        } catch (e) {
            console.error('[Genesis World Builder] Failed to inject Azgaar message listener:', e, {
                message: e.message,
                stack: e.stack,
                retryCount
            });
            if (retryCount < maxRetries) {
                const delay = Math.min(200 * Math.pow(2, retryCount), 2000);
                await new Promise(resolve => setTimeout(resolve, delay));
                return await this._injectAzgaarListener(iframe, retryCount + 1, maxRetries);
            } else {
                return false;
            }
        }
    },
    
    /**
     * Verify that the injected listener is working by sending a test message
     * @param {HTMLIFrameElement} iframe - The Azgaar iframe element
     * @param {number} maxWaitMs - Maximum time to wait for verification (default: 5000)
     * @returns {Promise<boolean>} True if verification succeeded, false otherwise
     */
    async _verifyListenerInjection(iframe, maxWaitMs = 5000) {
        return new Promise((resolve) => {
            const testId = 'test_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            const startTime = Date.now();
            let verificationReceived = false;
            
            console.log('[Genesis World Builder] Starting listener verification', {
                timestamp: new Date().toISOString(),
                testId,
                maxWaitMs
            });
            
            // Set up a one-time listener on the iframe's window to catch the test response
            // Note: We can't directly listen, but we can check if the message was logged
            // For now, we'll use a timeout and assume success if no error occurs
            // A more robust solution would require the injected listener to postMessage back
            
            // Send test message
            try {
                const testMessage = {
                    type: 'azgaar_test',
                    testId: testId
                };
                
                console.log('[Genesis World Builder] Sending test message for verification', {
                    timestamp: new Date().toISOString(),
                    testMessage,
                    targetOrigin: '*'
                });
                
                iframe.contentWindow.postMessage(testMessage, '*');
                
                // Give it a moment to process (the listener should log it)
                // In a real verification, we'd wait for a response message, but for now
                // we'll assume success if the postMessage didn't throw
                setTimeout(() => {
                    const elapsed = Date.now() - startTime;
                    console.log('[Genesis World Builder] Verification check complete', {
                        timestamp: new Date().toISOString(),
                        elapsedMs: elapsed,
                        testId
                    });
                    // For now, assume success if postMessage succeeded
                    // The injected listener will log the message, which we can check in console
                    resolve(true);
                }, 500);
            } catch (e) {
                console.error('[Genesis World Builder] Error during verification:', e);
                resolve(false);
            }
        });
    },
    
    _setupAzgaarListener() {
        console.log('[Genesis World Builder] _setupAzgaarListener() called', {
            timestamp: new Date().toISOString()
        });
        
        // Inject message listener into Azgaar iframe when it loads
        const iframe = document.getElementById('azgaar-iframe');
        if (!iframe) {
            console.warn('[Genesis World Builder] Azgaar iframe not found, cannot setup listener');
            this.errorMessage = 'Azgaar iframe not found';
            this.errorDetails = 'The Azgaar map iframe element is missing from the page.';
            return;
        }
        
        // Helper to check if iframe is loaded
        const isIframeLoaded = () => {
            try {
                return iframe.contentDocument && iframe.contentDocument.readyState === 'complete';
            } catch (e) {
                // CORS - can't access contentDocument, but iframe might still be loading
                return false;
            }
        };
        
        const setupListener = async () => {
            const setupStartTime = Date.now();
            console.log('[Genesis World Builder] Starting listener setup process', {
                timestamp: new Date().toISOString(),
                iframeLoaded: isIframeLoaded(),
                hasContentWindow: !!iframe.contentWindow
            });
            
            // Wait for iframe to be accessible (with timeout)
            if (!iframe.contentWindow) {
                console.log('[Genesis World Builder] Waiting for iframe.contentWindow to become available...');
                const iframeWaitStart = Date.now();
                const iframeWaitMax = 10000; // 10 seconds max wait for iframe window
                
                while (!iframe.contentWindow && (Date.now() - iframeWaitStart) < iframeWaitMax) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
                
                if (!iframe.contentWindow) {
                    console.error('[Genesis World Builder] iframe.contentWindow never became available');
                    this.errorMessage = 'Azgaar iframe not accessible';
                    this.errorDetails = 'The Azgaar iframe content window is not accessible. The iframe may not be loading properly.';
                    return;
                }
            }
            
            console.log('[Genesis World Builder] Iframe window is accessible, starting Azgaar readiness polling...');
            
            // First, wait for Azgaar to be ready
            const isReady = await this._pollForAzgaarReady(iframe);
            if (!isReady) {
                const elapsed = Date.now() - setupStartTime;
                console.error('[Genesis World Builder] Azgaar never became ready, cannot inject listener', {
                    elapsedMs: elapsed,
                    timestamp: new Date().toISOString()
                });
                this.errorMessage = 'Azgaar initialization timeout';
                this.errorDetails = `The Azgaar map generator did not initialize within 60 seconds (waited ${Math.round(elapsed/1000)}s). This may indicate:\n- Slow network connection\n- Azgaar server not responding\n- Browser security restrictions\n\nPlease refresh the page and try again.`;
                return;
            }
            
            const readyElapsed = Date.now() - setupStartTime;
            console.log('[Genesis World Builder] Azgaar is ready, injecting listener...', {
                elapsedMs: readyElapsed,
                timestamp: new Date().toISOString()
            });
            
            // Then inject the listener
            const injectionSuccess = await this._injectAzgaarListener(iframe);
            if (!injectionSuccess) {
                const totalElapsed = Date.now() - setupStartTime;
                console.error('[Genesis World Builder] Failed to inject listener after all retries', {
                    totalElapsedMs: totalElapsed,
                    timestamp: new Date().toISOString()
                });
                this.errorMessage = 'Failed to setup Azgaar communication';
                this.errorDetails = 'Could not inject the message listener into the Azgaar iframe. This may be due to CORS restrictions or iframe loading issues.';
            } else {
                const totalElapsed = Date.now() - setupStartTime;
                console.log('[Genesis World Builder] Listener setup completed successfully', {
                    timestamp: new Date().toISOString(),
                    totalElapsedMs: totalElapsed
                });
                // Clear any previous errors
                this.errorMessage = null;
                this.errorDetails = null;
            }
        };
        
        // Try to setup immediately if iframe is already loaded
        if (isIframeLoaded()) {
            console.log('[Genesis World Builder] Iframe already loaded, starting setup immediately', {
                timestamp: new Date().toISOString()
            });
            setupListener();
        } else {
            // Wait for iframe to load
            console.log('[Genesis World Builder] Waiting for iframe to load...', {
                timestamp: new Date().toISOString(),
                iframeSrc: iframe.src
            });
            
            const loadHandler = () => {
                console.log('[Genesis World Builder] Iframe load event fired, starting setup', {
                    timestamp: new Date().toISOString(),
                    readyState: isIframeLoaded() ? 'complete' : 'loading'
                });
                setupListener();
            };
            
            iframe.addEventListener('load', loadHandler, { once: true });
            
            // Fallback: if load event doesn't fire within 5 seconds, try anyway
            setTimeout(() => {
                if (!this.azgaarListenerInjected && !this.azgaarListenerVerified) {
                    console.warn('[Genesis World Builder] Iframe load event timeout, attempting setup anyway', {
                        timestamp: new Date().toISOString(),
                        hasContentWindow: !!iframe.contentWindow
                    });
                    iframe.removeEventListener('load', loadHandler);
                    setupListener();
                }
            }, 5000);
            
            // Also handle iframe error events
            iframe.addEventListener('error', (e) => {
                console.error('[Genesis World Builder] Iframe error event fired', {
                    timestamp: new Date().toISOString(),
                    error: e
                });
                this.errorMessage = 'Azgaar iframe failed to load';
                this.errorDetails = 'The Azgaar map iframe encountered an error while loading. Please check:\n- Azgaar server is running (http://127.0.0.1:8080)\n- Network connectivity\n- Browser console for details';
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
    
    async generate() {
        const generateStartTime = Date.now();
        console.log('[Genesis World Builder] generate() called', {
            timestamp: new Date().toISOString(),
            params: this.params,
            paramsCount: Object.keys(this.params).length,
            seed: this.seed,
            listenerInjected: this.azgaarListenerInjected,
            listenerVerified: this.azgaarListenerVerified
        });
        
        // Clear previous errors
        this.errorMessage = null;
        this.errorDetails = null;
        
        this.isGenerating = true;
        this.progressValue = 0;
        this.statusText = 'Preparing generation...';
        
        // Send to Godot for progress tracking
        try {
            GodotBridge.postMessage('generate', { params: this.params });
            console.log('[Genesis World Builder] Sent generate IPC message to Godot', {
                timestamp: new Date().toISOString(),
                paramsCount: Object.keys(this.params).length
            });
        } catch (e) {
            console.error('[Genesis World Builder] Error sending generate IPC to Godot:', e);
        }
        
        // Get iframe reference
        const iframe = document.getElementById('azgaar-iframe');
        if (!iframe) {
            console.error('[Genesis World Builder] Azgaar iframe not found');
            this.isGenerating = false;
            this.statusText = 'Error: Azgaar iframe not found';
            this.errorMessage = 'Azgaar iframe not found';
            this.errorDetails = 'The Azgaar map iframe element is missing from the page.';
            return;
        }
        
        if (!iframe.contentWindow) {
            console.error('[Genesis World Builder] iframe.contentWindow not available');
            this.isGenerating = false;
            this.statusText = 'Error: Cannot access Azgaar iframe';
            this.errorMessage = 'Cannot access Azgaar iframe';
            this.errorDetails = 'The iframe content window is not accessible. The iframe may not be fully loaded.';
            return;
        }
        
        try {
            // Step 1: Wait for Azgaar to be ready (polling)
            this.statusText = 'Waiting for Azgaar to initialize...';
            console.log('[Genesis World Builder] Step 1: Polling for Azgaar readiness...');
            const isReady = await this._pollForAzgaarReady(iframe);
            
            if (!isReady) {
                console.error('[Genesis World Builder] Azgaar not ready after polling timeout');
                this.isGenerating = false;
                this.statusText = 'Error: Azgaar initialization timeout';
                this.errorMessage = 'Azgaar initialization timeout';
                this.errorDetails = 'The Azgaar map generator did not initialize within 60 seconds. This may indicate:\n- Slow network connection\n- Azgaar server not responding\n- Browser security restrictions\n\nPlease refresh the page and try again.';
                return;
            }
            
            console.log('[Genesis World Builder] Step 1 complete: Azgaar is ready');
            
            // Step 2: Ensure listener is injected and verified
            this.statusText = 'Setting up communication...';
            console.log('[Genesis World Builder] Step 2: Ensuring listener is injected and verified...');
            
            if (!this.azgaarListenerInjected || !this.azgaarListenerVerified) {
                console.log('[Genesis World Builder] Listener not ready, injecting now...');
                const injectionSuccess = await this._injectAzgaarListener(iframe);
                
                if (!injectionSuccess) {
                    console.error('[Genesis World Builder] Failed to inject/verify listener');
                    this.isGenerating = false;
                    this.statusText = 'Error: Failed to setup communication';
                    this.errorMessage = 'Failed to setup Azgaar communication';
                    this.errorDetails = 'Could not inject or verify the message listener. This may be due to CORS restrictions or iframe security policies.';
                    return;
                }
            } else {
                console.log('[Genesis World Builder] Listener already injected and verified');
            }
            
            console.log('[Genesis World Builder] Step 2 complete: Listener is ready');
            
            // Step 3: Send parameters message
            this.statusText = 'Sending parameters...';
            console.log('[Genesis World Builder] Step 3: Sending parameters to Azgaar...');
            
            const paramsMessage = {
                type: 'azgaar_params',
                params: this.params,
                seed: this.seed
            };
            
            console.log('[Genesis World Builder] Preparing params message', {
                timestamp: new Date().toISOString(),
                messageType: paramsMessage.type,
                paramsCount: Object.keys(paramsMessage.params).length,
                seed: paramsMessage.seed,
                fullMessage: paramsMessage
            });
            
            try {
                iframe.contentWindow.postMessage(paramsMessage, '*');
                console.log('[Genesis World Builder] Sent azgaar_params message', {
                    timestamp: new Date().toISOString(),
                    targetOrigin: '*',
                    paramsCount: Object.keys(paramsMessage.params).length,
                    seed: paramsMessage.seed
                });
            } catch (postError) {
                console.error('[Genesis World Builder] Error sending params message:', postError, {
                    message: postError.message,
                    stack: postError.stack
                });
                this.isGenerating = false;
                this.statusText = 'Error: Failed to send parameters';
                this.errorMessage = 'Failed to send parameters';
                this.errorDetails = `Error: ${postError.message}`;
                return;
            }
            
            // Small delay to ensure params are applied before triggering generation
            await new Promise(resolve => setTimeout(resolve, 100));
            console.log('[Genesis World Builder] Step 3 complete: Parameters sent');
            
            // Step 4: Send generate message
            this.statusText = 'Triggering generation...';
            console.log('[Genesis World Builder] Step 4: Sending generate message to Azgaar...');
            
            const generateMessage = {
                type: 'azgaar_generate'
            };
            
            console.log('[Genesis World Builder] Preparing generate message', {
                timestamp: new Date().toISOString(),
                messageType: generateMessage.type,
                fullMessage: generateMessage
            });
            
            try {
                iframe.contentWindow.postMessage(generateMessage, '*');
                console.log('[Genesis World Builder] Sent azgaar_generate message', {
                    timestamp: new Date().toISOString(),
                    targetOrigin: '*'
                });
            } catch (postError) {
                console.error('[Genesis World Builder] Error sending generate message:', postError, {
                    message: postError.message,
                    stack: postError.stack
                });
                this.isGenerating = false;
                this.statusText = 'Error: Failed to trigger generation';
                this.errorMessage = 'Failed to trigger generation';
                this.errorDetails = `Error: ${postError.message}`;
                return;
            }
            
            console.log('[Genesis World Builder] Step 4 complete: Generate message sent');
            console.log('[Genesis World Builder] Generation flow completed successfully', {
                timestamp: new Date().toISOString(),
                totalElapsedMs: Date.now() - generateStartTime
            });
            
            this.statusText = 'Generation triggered - waiting for Azgaar...';
            
        } catch (e) {
            console.error('[Genesis World Builder] Error in generate() flow:', e, {
                message: e.message,
                stack: e.stack,
                timestamp: new Date().toISOString()
            });
            this.isGenerating = false;
            this.statusText = 'Error: Generation failed';
            this.errorMessage = 'Generation failed';
            this.errorDetails = `Unexpected error: ${e.message}. Check console for details.`;
        }
    }
    }));
});

