require 'monkeypatch'

# Define a new extension that adds the #to_blob method
date_patch = MonkeyPatch.add_method(:to_blob) do
  def to_blob; "<blob>" end
end

x = "something"
date_patch.patch_instance(x)
x.to_blob #=> "<blob>"

# Define a patch, that replaces the #to_date method
each_patch = MonkeyPatch.replace_method(:to_s) do
  def to_s; "..." end
end

class ExampleClass
  def to_s; "hello" end
end

(date_patch & each_patch).patch_class(ExampleClass)

ExampleClass.new.to_s #=> "..."
ExampleClass.new.to_blob #=> "<blob>"
