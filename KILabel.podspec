Pod::Spec.new do |s|

  s.name         = "KILabel"
  s.version      = "1.1.0"
  s.summary      = "Replacement for UILabel for iOS 7 and 8 that provides automatic detection of links such as URLs, twitter style usernames and hashtags."

  s.description  = <<-DESC
                   A simple to use drop in replacement for UILabel for iOS 7 and 8 that provides automatic detection of links such as URLs, twitter style usernames and hashtags.

                   KILabel is an alternative to UILabel that provides automatic link detection and hilighting for URLs, twitter handles, hashtags. The link types may be extended through custom link classifier objects. It also detects taps on links and allows you to respond via blocks. It is intended for use in Socal Networking apps like twitter clients but might be useful anywhere you require some extra formatting for text but don't want the overhead of using a text field.
                   DESC

  s.homepage     = "https://github.com/Krelborn/KILabel"
  s.screenshots  = "https://raw.githubusercontent.com/Krelborn/KILabel/master/IKLabelDemoScreenshot.png"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Matt Styles" => "matt@compiledcreations.com" }
  s.social_media_url   = "http://twitter.com/Krelborn"

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/Krelborn/KILabel.git", :tag => "1.1.0" }

  s.source_files  = "KILabel/Source/**/*.{h,m}"
  public_header_files = "KILabel/Source/**/*.h"

  s.frameworks = "UIKit", "Foundation"

  s.requires_arc = true

end
