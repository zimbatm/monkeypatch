require 'monkeypatch'

date_patch = MonkeyPatch.add_method(:to_date) do
  def to_blob; "<blob>" end
end

date_patch.patch_class(Time)

each_patch = MonkeyPatch.replace_method(:to_date) do
  def to_date(&proc); "..." end
end

(date_patch & each_patch).patch_class(Date)

Date.new.to_date #=> "..."
Date.new.to_blob #=> "<blob>"
