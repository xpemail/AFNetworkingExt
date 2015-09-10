 
Pod::Spec.new do |s|
 

  s.name         = "AFNetworkingExt"
  s.version      = "1.2.5"
  s.summary      = "AFNetworking的封装, 并提供一个 UIImageView+DYLoading  cache in fileSystem+memory"
 

  s.homepage     = "https://github.com/xpemail/AFNetworkingExt"
 
  s.license      = "MIT"
 
  s.author             = { "wuxiande" => "xd.wu@msn.com" } 
  s.ios.deployment_target = "6.0" 

  s.ios.framework = 'UIKit'
 
  s.source = { :git => 'https://github.com/xpemail/AFNetworkingExt.git' , :tag => '1.2.5'} 
 
  s.requires_arc = true
  
  s.subspec 'Base' do |ds|
    
    ds.source_files = 'Ext/*.{h,m,mm}'  
  
    ds.dependency 'AFNetworkingExt/AFCustomRequestOperation'
    ds.dependency 'AFNetworkingExt/AFDownloadRequestOperation'
    ds.dependency 'AFNetworkingExt/AFTextResponseSerializer'
    		 
  end 
  
      
  s.subspec 'AFCustomRequestOperation' do |ds|
    
    ds.source_files = 'AFCustomRequestOperation/*.{h,m,mm}'  
  
    		 
  end
  
  s.subspec 'AFDownloadRequestOperation' do |ds|
    
    ds.dependency 'AFNetworkingExt/AFCustomRequestOperation'
    ds.source_files = 'AFDownloadRequestOperation/*.{h,m,mm}'  
  end
  
  
  s.subspec 'AFTextResponseSerializer' do |ds|
    
    ds.source_files = 'AFTextResponseSerializer/*.{h,m,mm}' 
    		  
  end
  
  
  s.subspec 'example' do |ds|
    
    ds.dependency 'AFNetworkingExt/Base'
    ds.source_files = '*.{h,m,mm}' 
    		 
  end
  
  
  s.subspec 'UIKit' do |ks|
     
     ks.subspec 'UIImageView+DYLoading' do |ds|
     
     	ds.dependency 'AFNetworkingExt/AFDownloadRequestOperation'
        ds.dependency 'AFNetworkingExt/Base' 
    
     	ds.source_files = 'UIKit/UIImageView+DYLoading/*.{h,m,mm}' 
    		 
  	end
    		 
  end 
  
  s.dependency 'AFNetworking'
  s.dependency 'AFNetworkActivityLogger'
  s.dependency 'AFgzipRequestSerializer'
  s.dependency 'AFOnoResponseSerializer'
  s.dependency 'Godzippa'
   
 
end
