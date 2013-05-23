desc "Update pot/po files."
task :updatepo do
  require 'gettext/utils'

  puts "Generating pot files for lib"
  GetText.update_pofiles("restore", Dir.glob("{lib}/**/*.{rb,rhtml}"), "restore 4.0")
  
  Dir.chdir('frontend') do
    puts "Generating pot files for frontend"
    GetText.update_pofiles("restore-frontend", Dir.glob("{app,lib,bin}/**/*.{rb,rhtml}"), "restore 4.0")
  end
  
  Dir.glob("modules/*").each do |m|
    name = File.basename(m)
    puts "Generating pot files for #{name}"
    Dir.chdir(m) do
      GetText.update_pofiles("restore-module-#{name}", Dir.glob("**/*.{rb,rhtml}"), "restore #{m} module 4.0")    
    end
  end

end

desc "Create mo-files"
task :makemo do
  require 'gettext/utils'
  puts "Making mo files for lib"
  GetText.create_mofiles(true, "po", "locale")
  
  Dir.chdir('frontend') do
    puts "Making mo files for frontend"
    GetText.create_mofiles(true, "po", "locale")
  end
  
  Dir.glob("modules/*").each do |m|
    name = File.basename(m)
    puts "Making mo files for #{name}"
    Dir.chdir(m) do
      GetText.create_mofiles(true, "po", "locale")
    end
  end
  
end
