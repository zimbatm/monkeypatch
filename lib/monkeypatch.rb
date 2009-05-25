=begin rdoc

See README.rdoc

=end
module MonkeyPatch
  VERSION = '0.1.0'
  # May be raise on check_conflicts
  class ConflictError < StandardError; end
  
  # A collection of patches. Used to collect one or more patches with the #& operator
  # 
  # NOTE: didn't use the Set class, to not force a dependency
  class PatchSet
    def initialize(patches=[]); @patches = patches.to_a.uniq end
    
    def &(other)
      PatchSet.new(@patches + other.to_a)
    end
    def to_a; @patches.dup end
    
    # Delegates to patches
    # TODO: determine what happens if a patch fails
    def patch_class(klass)
      @patches.each do |patch|
        patch.patch_class(klass)
      end
    end
    
    # Delegates to patches
    def patch_instance(obj)
      for patch in @patches
        patch.patch_instance(obj)
      end
    end
  end
  
  class Patch
    class << self
      # Hide new to force api usage
      private :new
    end
    # The path it was defined in
    attr_reader :from
    
    def initialize(&patch_def)
      raise ArgumentError, "patch_def not given" unless block_given?
      @patch_def = patch_def
    end
    
    def &(other)
      PatchSet.new([self]) & other
    end
    
    def to_a; [self] end
  
    # Patches the class or module. Patches classes are kept track of
    def patch_class(klass)
      raise ArgumentError, "klass is not a Class" unless klass.kind_of?(Class)
      
      return false if !check_conditions(klass)
      
      check_conflicts!(klass)
        
      # Apply
      apply_patch(klass)
        
      return true
    end
    alias apply_to patch_class

    # Patches the instance's metaclass
    def patch_instance(obj)
      meta = (class << obj; self end)
      patch_class(meta)
    end
    
  protected
  
    # Condition are checks that raise nothing
    # 
    # If a condition isn't met, the patch is not applied
    #
    # Returns true if all conditions are matched
    def check_conditions(klass);
      if klass.respond_to?(:applied_patches) && klass.applied_patches.include?(self)
        log "WARN: Patch already applied"
        return false
      end
      true
    end
  
    # Re-implement in childs. Make sure super is called
    # 
    # raises a ConflictError if an error is found 
    def check_conflicts!(klass); nil end
    
    def apply_patch(klass)
      klass.extend IsPatched
      klass.class_eval(&@patch_def)
      klass.applied_patches.push self
    end
    
    def log(msg); MonkeyPatch.logger.log(msg) end
  end
  
  class MethodPatch < Patch
    attr_reader :method_name
    def initialize(method_name, &patch_def)
      super(&patch_def)
      @method_name = method_name.to_s
      unless Module.new(&patch_def).instance_methods(true) == [@method_name]
        raise ArgumentError, "&patch_def does not define the specified method"
      end 
    end
    
  protected
    def check_conflicts!(klass)
      super
      if klass.respond_to? :applied_patches
        others = klass.applied_patches.select{|p| p.respond_to?(:method_name) && p.method_name == method_name }
        if others.any?
          raise ConflictError, "Conflicting patches: #{([self] + others).inspect}"
        end
      end
    end
  end
  
  class AddMethodPatch < MethodPatch
  protected
    def check_conflicts!(klass)
      super
      if klass.method_defined?(method_name)
        raise ConflictError, "Add already existing method #{method_name} in #{klass}"
      end
    end
  end
  
  class ReplaceMethodPatch < MethodPatch
  protected
    def check_conflicts!(klass)
      super
      unless klass.method_defined?(method_name)
        raise ConflictError, "Replacing method #{method_name} does not exist in #{klass}"
      end
    end
  end
  
  # Default MonkeyPatch::logger . Use the same interface
  # if you want to replace it.
  class STDERRLogger
    def log(msg); STDERR.puts msg end
  end
  
  # Included in patched objects, maybe add some utility methods ?
  module IsPatched
    def applied_patches; @__applied_patches__ ||= [] end
  end
  
  @logger = STDERRLogger.new
  @loaded_patches = []
  @patch_registry = Hash.new([])
  class << self
    # Here goes the messages, this object should respond_to? :log
    # Default is STDERRLogger
    attr_accessor :logger
    
    attr_reader :loaded_patches
    # Here we keep track of all patched classes
    attr_reader :patch_registry
    
    # Creates a new patch that adds a method to a class or a module
    # 
    # Returns a AddMethodPatch
    def add_method(method_name, &definition)
      new_patch AddMethodPatch.send(:new, method_name, &definition)
    end
    
    # Creates a new patch that replaces a method of a class or a module
    #
    # Returns a ReplaceMethodPatch
    def replace_method(method_name, &definition)
      new_patch ReplaceMethodPatch.send(:new, method_name, &definition)
    end
    
    #def rename_method(method_name, new_method_name)
      # TODO
    #end
    
    #def deprecate_method(method_name)
      # TODO
    #end
  
  protected
    
    def new_patch(patch, &definition)
      #patch.validate
      patch.instance_variable_set(:@from, caller[1])
      @loaded_patches.push(patch)
      patch
    end
  
  end
end

