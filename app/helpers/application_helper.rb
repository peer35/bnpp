module ApplicationHelper
  def linebreak_helper args
    args[:document][args[:field]].gsub(/;\s/,'<br>').html_safe
  end

  def vv_helper args
    val=args[:document][args[:field]]
    vvtitels=[]
    vals=val.split(';')
    for v in vals
        /(vv|va)\s(?<titel>[^:,]*)/ =~ v.strip()
        if titel
          vvtitels.append(titel)unless vvtitels.include?(titel)
        end
    end
    for titel in vvtitels
      url = link_to titel, search_action_url(search_field: 'titel_s', q: titel)
      val=val.gsub(titel, url)
    end
    val.html_safe
  end
end
