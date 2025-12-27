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

// Alpine.js data component
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
    
    init() {
        // Store instance for global access
        window.worldBuilderInstance = this;
        
        // Lazy initialization: defer heavy data requests until after DOM is ready
        // This reduces blocking time during Alpine.js initialization
        if (document.readyState === 'loading') {
            // DOM not ready yet, wait for it
            document.addEventListener('DOMContentLoaded', () => {
                this._lazyInit();
            });
        } else {
            // DOM already ready, but defer to next frame to allow Alpine to finish init
            requestAnimationFrame(() => {
                this._lazyInit();
            });
        }
        
        // Send initial step (non-blocking)
        this.setStep(0);
    },
    
    _lazyInit() {
        // Lazy initialization: load step definitions and initialize params
        // Check if steps data was stored before Alpine initialized
        if (window._pendingStepsData && window._pendingStepsData.steps) {
            this.steps = window._pendingStepsData.steps;
            this._initializeParamsForStep(0); // Only init current step
            delete window._pendingStepsData;
        } else {
            // Request step definitions from Godot (deferred)
            GodotBridge.requestData('step_definitions', (data) => {
                if (data && data.steps) {
                    this.steps = data.steps;
                    // Initialize params only for current step (chunked)
                    this._initializeParamsForStep(this.currentStep);
                }
            });
        }
    },
    
    _initializeParams() {
        // DEPRECATED: Use _initializeParamsForStep() instead for chunked initialization
        // Initialize params with default values from step definitions (all steps)
        for (let step of this.steps) {
            if (step.parameters) {
                for (let param of step.parameters) {
                    if (!(param.azgaar_key in this.params)) {
                        this.params[param.azgaar_key] = param.default !== undefined ? param.default : 
                            (param.ui_type === 'CheckBox' ? false : 0);
                    }
                }
            }
        }
    },
    
    _initializeParamsForStep(stepIndex) {
        // Chunked initialization: only initialize params for a specific step
        // This reduces initial blocking time by spreading work across frames
        if (!this.steps || stepIndex < 0 || stepIndex >= this.steps.length) {
            return;
        }
        
        var step = this.steps[stepIndex];
        if (step && step.parameters) {
            for (let param of step.parameters) {
                if (!(param.azgaar_key in this.params)) {
                    this.params[param.azgaar_key] = param.default !== undefined ? param.default : 
                        (param.ui_type === 'CheckBox' ? false : 0);
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
        if (this.steps && this.steps[this.currentStep]) {
            return this.steps[this.currentStep].parameters || [];
        }
        return [];
    },
    
    setStep(index) {
        if (index >= 0 && index < this.totalSteps) {
            this.currentStep = index;
            GodotBridge.postMessage('set_step', { step: index });
            
            // Chunked param initialization: initialize params for new step if not already done
            if (this.steps && this.steps[index]) {
                // Defer param initialization to avoid blocking step change
                requestAnimationFrame(() => {
                    this._initializeParamsForStep(index);
                });
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
        this.params[key] = value;
        GodotBridge.postMessage('update_param', { 
            azgaar_key: key, 
            value: value 
        });
    },
    
    generate() {
        this.isGenerating = true;
        this.progressValue = 0;
        this.statusText = 'Generating...';
        GodotBridge.postMessage('generate', { params: this.params });
    }
}));

