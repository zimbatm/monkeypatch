require 'test/unit'

require 'monkeypatch'

class TestMonkeypatch < Test::Unit::TestCase
  include MonkeyPatch
  
  class FakeLogger
    attr_reader :logs
    def initialize
      @logs = []
    end
    def log(msg)
      @logs.push msg
    end
  end
  
  def setup
    @logger = MonkeyPatch.logger = FakeLogger.new
    @logs = @logger.logs
    @c = Class.new do
      def existing_method; "original" end
    end
    @p_add = MonkeyPatch.add_method(:new_method) do
      def new_method; "exists" end
    end
    @p_repl = MonkeyPatch.replace_method(:existing_method) do
      def existing_method; "replaced" end
    end
  end
  
  def test_invalid_patches
    assert_raise(ArgumentError) do
      MonkeyPatch.add_method(:new_method)
    end
    assert_raise(ArgumentError) do
      MonkeyPatch.replace_method(:new_method)
    end
    assert_raise(ArgumentError) do
      MonkeyPatch.add_method(:new_method) do
        def new_method_typo; end
      end
    end
  end

  def test_do_not_apply_twice
    @p_add.patch_class(@c)
    @p_add.patch_class(@c)
    assert_equal 1, @logs.size, "Should be the notice about the twice application"
    assert_equal [@p_add], @c.applied_patches
  end
  
  def test_add_method
    @p_add.patch_class(@c)
    
    assert_equal("exists", @c.new.new_method )
  end

  def test_check_conflict
    p1 = MonkeyPatch.add_method(:some) do
      def some; "one" end
    end
    p2 = MonkeyPatch.add_method(:some) do
      def some; "thing" end
    end
    c = Class.new
    assert_nothing_raised do
      p1.patch_class(c)
    end
    assert_raise(ConflictError) do
      p2.patch_class(c)
    end
  end
  
  def test_replace_method
    @p_repl.patch_class(@c)
    
    assert @c.respond_to?(:applied_patches)
    
    assert_equal("replaced", @c.new.existing_method )
  end
  
  def test_patch_class_application
    assert !@c.new.respond_to?(:applied_patches)
    @p_add.patch_class(@c)
    assert_respond_to @c, :applied_patches
    
    assert_equal [@p_add], @c.applied_patches
    
    @p_repl.patch_class(@c)
    assert_equal [@p_add, @p_repl], @c.applied_patches
  end
  
  def test_patch_instance_application
    p = MonkeyPatch.replace_method(:to_s) do
      def to_s; "right" end
    end
    i = "left"
    p.patch_instance(i)
    assert_equal("right", i.to_s)
  end
  
  def test_replace_conflict
    c = Class.new
    assert_raise(ConflictError) do
      @p_repl.patch_class(c)
    end
    assert !c.new.respond_to?(:existing_method)
  end
  
  def test_add_method_conflict
    c = Class.new do
      def new_method; "not replaced" end
    end
    assert_raise(ConflictError) do
      @p_add.patch_class(c)
    end
    assert_equal "not replaced", c.new.new_method
  end
  
  def test_patch_from
    assert_equal(File.basename(__FILE__), File.basename(@p_add.from).gsub(/:.*/,''))
  end
  
  def test_patch_set
    both = (@p_add & @p_repl)
    assert_equal(PatchSet, both.class)
    
    inst = @c.new
    both.patch_instance(inst)
    assert_equal("exists", inst.new_method )
    assert_equal("replaced", inst.existing_method )
    
    both.patch_class(@c)
    assert_equal("exists", @c.new.new_method )
    assert_equal("replaced", @c.new.existing_method )
  end
  
end
