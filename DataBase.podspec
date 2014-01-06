Pod::Spec.new do |s|

  s.name         = "DataBase"
  s.version      = "0.0.1"
  s.summary      = "DataBase"

  s.description  = <<-DESC
  					DataBase
                   DESC

  s.homepage     = "http://github.com/dictav/DataBase"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "dictav" => "dictav@gmail.com" }
  s.social_media_url = "http://twitter.com/dictav"

  s.source       = { :git => "https://github.com/dictav/DataBase.git", :tag => "0.0.1" }
  s.source_files  = 'DataBase/*.{h,m}'

  s.requires_arc  = true
end
