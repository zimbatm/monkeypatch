require 'monkeypatch'

# Define a new extension that adds the #to_blob method
blob_patch = MonkeyPatch.add_method(:to_blob) do
  def to_blob; "<blob>" end
end

x = "something"
blob_patch.patch_instance(x)
x.to_blob #=> "<blob>"

# Define a patch, that replaces the #to_date method
str_patch = MonkeyPatch.replace_method(:to_s) do
  def to_s; "..." end
end

class ExampleClass
  def to_s; "hello" end
end

(blob_patch & str_patch).patch_class(ExampleClass)

ExampleClass.new.to_s #=> "..."
ExampleClass.new.to_blob #=> "<blob>"

