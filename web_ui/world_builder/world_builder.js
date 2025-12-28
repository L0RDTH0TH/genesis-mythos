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
        
        // Check if steps data was stored before Alpine initialized
        if (window._pendingStepsData && window._pendingStepsData.steps) {
            this.steps = window._pendingStepsData.steps;
            this._initializeParams();
            delete window._pendingStepsData;
        } else {
            // Request step definitions from Godot
            GodotBridge.requestData('step_definitions', (data) => {
                if (data && data.steps) {
                    this.steps = data.steps;
                    // Initialize params with defaults from first step
                    this._initializeParams();
                }
            });
        }
        
        // Request archetypes (already have names, but can request full data if needed)
        // Archetype names are already set in archetypeNames array
        
        // Send initial step
        this.setStep(0);
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
        if (this.steps && this.steps[this.currentStep]) {
            // Filter to only show curated parameters
            const allParams = this.steps[this.currentStep].parameters || [];
            return allParams.filter(param => param.curated !== false);
        }
        return [];
    },
    
    setStep(index) {
        if (index >= 0 && index < this.totalSteps) {
            this.currentStep = index;
            GodotBridge.postMessage('set_step', { step: index });
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
        }
        
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

