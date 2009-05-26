=begin rdoc

This is the public API to produce new patches.

Once you have a patch, look at Patch and it's children to see how to use it.

=end
module MonkeyPatch
  # MonkeyPatch's version as a string
  VERSION = '0.1.1'
  # May be raised on check_conflicts
  class ConflictError < StandardError; end
  
  # A collection of patches. Used to collect one or more patches with the #& operator
  # 
  # NOTE: didn't use the Set class, to not force a dependency
  class PatchSet
    def initialize(patches) #:nodoc:
      @patches = patches.to_a.uniq
    end
    
    # Aggregates Patch (es) and PatchSet (s)
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
  
  # Abstract definition of a patch.
  # 
  # You cannot create Patch instance yourself, they are spawned from 
  # MonkeyPatch class-methods.
  class Patch
    class << self
      # Hide new to force api usage
      private :new
    end
    # The callstack it was defined in
    attr_reader :from
    
    def initialize(&patch_def) #:nodoc:
      raise ArgumentError, "patch_def not given" unless block_given?
      @patch_def = patch_def
      @conditions = []
      add_condition("Patch already applied") do |klass|
        !(klass.respond_to?(:applied_patches) && klass.applied_patches.include?(self))
      end
    end
    
    # Combine patches together. Produces a PatchSet instance.
    def &(other)
      PatchSet.new([self]) & other
    end
    
    # Returns [self], used by #&
    def to_a; [self] end
  
    # Patches a class or module instance methods
    def patch_class(klass)
      raise ArgumentError, "klass is not a Class" unless klass.kind_of?(Class)
      
      return false if !check_conditions(klass)
      
      check_conflicts!(klass)
        
      # Apply
      apply_patch(klass)
        
      return true
    end

    # Patches the instance's metaclass
    def patch_instance(obj)
      meta = (class << obj; self end)
      patch_class(meta)
    end
    
    # Add a condition for patch application, like library version
    # 
    # If condition is not matched, +msg+ is 
    def add_condition(msg, &block)
      raise ArgumentError, "block is missing" unless block_given?
      @conditions.push [block, msg]
    end
    
  protected
  
    # Condition are checks that raise nothing
    # 
    # If a condition isn't met, the patch is not applied
    #
    # Returns true if all conditions are matched
    def check_conditions(klass) #:nodoc:
      !@conditions.find do |tuple|
        if tuple[0].call(klass); false
        else
          log tuple[1]
          true
        end
      end
    end
  
    # Re-implement in childs. Make sure super is called
    # 
    # raises a ConflictError if an error is found 
    def check_conflicts!(klass) #:nodoc:
    end
    
    def apply_patch(klass) #:nodoc:
      klass.extend IsPatched
      klass.class_eval(&@patch_def)
      klass.applied_patches.push self
    end
    
    def log(msg) #:nodoc:
      MonkeyPatch.logger.log(msg)
    end
  end
  
  class MethodPatch < Patch
    # The name of the method to be patched
    attr_reader :method_name
    def initialize(method_name, &patch_def) #:nodoc:
      super(&patch_def)
      @method_name = method_name.to_s
      unless Module.new(&patch_def).instance_methods(true) == [@method_name]
        raise ArgumentError, "&patch_def does not define the specified method"
      end 
    end
    
  protected
    def check_conflicts!(klass) #:nodoc:
      super
      if klass.respond_to? :applied_patches
        others = klass.applied_patches.select{|p| p.respond_to?(:method_name) && p.method_name == method_name }
        if others.any?
          raise ConflictError, "Conflicting patches: #{([self] + others).inspect}"
        end
      end
    end
  end
  
  # Spawned by MonkeyPatch.add_method
  class AddMethodPatch < MethodPatch
  protected
    def check_conflicts!(klass) #:nodoc:
      super
      if klass.method_defined?(method_name)
        raise ConflictError, "Add already existing method #{method_name} in #{klass}"
      end
    end
  end
  
  # Spawned by MonkeyPatch.replace_method
  class ReplaceMethodPatch < MethodPatch
  protected
    def check_conflicts!(klass) #:nodoc:
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
  
  # This module extends patched objects to keep track of the applied patches
  module IsPatched
    def applied_patches; @__applied_patches__ ||= [] end
  end
  
  @logger = STDERRLogger.new
  @loaded_patches = []
  class << self
    # Here goes the messages, this object should respond_to? :log
    # Default is STDERRLogger
    attr_accessor :logger
    
    # All defined patches are stored here
    attr_reader :loaded_patches
    
    # Creates a new patch that adds a method to a class or a module
    # 
    # Returns a Patch (AddMethodPatch)
    def add_method(method_name, &definition)
      new_patch AddMethodPatch.send(:new, method_name, &definition)
    end
    
    # Creates a new patch that replaces a method of a class or a module
    #
    # Returns a Patch (ReplaceMethodPatch)
    def replace_method(method_name, &definition)
      new_patch ReplaceMethodPatch.send(:new, method_name, &definition)
    end
  
  protected
    
    def new_patch(patch, &definition) #:nodoc:
      #patch.validate
      patch.instance_variable_set(:@from, caller[1])
      @loaded_patches.push(patch)
      patch
    end
  
  end
end

