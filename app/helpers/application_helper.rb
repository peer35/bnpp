module ApplicationHelper
  def linebreak_helper args
    args[:document][args[:field]].gsub(/;\s/,'<br>').html_safe
  end
end
