// ╔═══════════════════════════════════════════════════════════
// ║ world_builder.js
// ║ Desc: Alpine.js data and logic for World Builder UI
// ║ Author: Lordthoth
// ╚═══════════════════════════════════════════════════════════

// Alpine.js data component for World Builder
document.addEventListener('alpine:init', () => {
    Alpine.data('worldBuilder', () => ({
        // Current step (0-7)
        currentStep: 0,
        totalSteps: 8,
        
        // Step definitions (loaded from Godot)
        stepDefinitions: [],
        
        // Current parameters (synced with Godot)
        parameters: {},
        
        // Step titles
        stepTitles: [
            '1. Map Generation & Editing',
            '2. Terrain',
            '3. Climate',
            '4. Biomes',
            '5. Structures & Civilizations',
            '6. Environment',
            '7. Resources & Magic',
            '8. Export'
        ],
        
        // Loading state
        isLoading: false,
        progress: 0,
        status: 'Ready',
        
        // Initialize
        init() {
            console.log('[WorldBuilder] Initialized');
            
            // Listen for messages from Godot
            window.addEventListener('godot-message', (event) => {
                this.handleGodotMessage(event.detail);
            });
            
            // Request step definitions from Godot
            this.requestStepDefinitions();
        },
        
        // Handle messages from Godot
        handleGodotMessage(message) {
            if (!message || !message.type) return;
            
            switch (message.type) {
                case 'step_definitions':
                    this.stepDefinitions = message.data.steps || [];
                    console.log('[WorldBuilder] Step definitions loaded:', this.stepDefinitions.length);
                    break;
                    
                case 'parameters':
                    this.parameters = message.data.parameters || {};
                    console.log('[WorldBuilder] Parameters synced:', Object.keys(this.parameters).length);
                    break;
                    
                case 'step_changed':
                    this.currentStep = message.data.step || 0;
                    console.log('[WorldBuilder] Step changed to:', this.currentStep);
                    break;
                    
                case 'generation_progress':
                    this.progress = message.data.progress || 0;
                    this.status = message.data.status || 'Generating...';
                    this.isLoading = this.progress < 100;
                    break;
                    
                case 'generation_complete':
                    this.isLoading = false;
                    this.progress = 100;
                    this.status = 'Generation complete!';
                    break;
                    
                case 'generation_failed':
                    this.isLoading = false;
                    this.status = 'Generation failed: ' + (message.data.reason || 'Unknown error');
                    break;
            }
        },
        
        // Request step definitions from Godot
        requestStepDefinitions() {
            if (window.GodotBridge) {
                window.GodotBridge.postMessage('request_step_definitions', {});
            }
        },
        
        // Navigate to step
        goToStep(step) {
            if (step < 0 || step >= this.totalSteps) return;
            
            this.currentStep = step;
            
            if (window.GodotBridge) {
                window.GodotBridge.postMessage('step_changed', { step: step });
            }
        },
        
        // Navigate to previous step
        previousStep() {
            if (this.currentStep > 0) {
                this.goToStep(this.currentStep - 1);
            }
        },
        
        // Navigate to next step
        nextStep() {
            if (this.currentStep < this.totalSteps - 1) {
                this.goToStep(this.currentStep + 1);
            }
        },
        
        // Update parameter value
        updateParameter(key, value) {
            this.parameters[key] = value;
            
            if (window.GodotBridge) {
                window.GodotBridge.postMessage('parameter_changed', {
                    key: key,
                    value: value
                });
            }
        },
        
        // Trigger generation
        generate() {
            this.isLoading = true;
            this.progress = 0;
            this.status = 'Generating map...';
            
            if (window.GodotBridge) {
                window.GodotBridge.postMessage('generate', {
                    parameters: this.parameters
                });
            }
        },
        
        // Get current step title
        getCurrentStepTitle() {
            if (this.stepDefinitions.length > 0 && this.stepDefinitions[this.currentStep]) {
                return this.stepDefinitions[this.currentStep].title || this.stepTitles[this.currentStep];
            }
            return this.stepTitles[this.currentStep] || 'Unknown Step';
        },
        
        // Get parameters for current step
        getCurrentStepParameters() {
            if (this.stepDefinitions.length > 0 && this.stepDefinitions[this.currentStep]) {
                return this.stepDefinitions[this.currentStep].parameters || [];
            }
            return [];
        },
        
        // Check if can go back
        canGoBack() {
            return this.currentStep > 0;
        },
        
        // Check if can go next
        canGoNext() {
            return this.currentStep < this.totalSteps - 1;
        },
        
        // Check if is export step
        isExportStep() {
            return this.currentStep === 7;
        }
    }));
});

