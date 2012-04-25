require "buffet"
require "rvm"
require "rvm/capistrano"

Capistrano::Configuration.instance(true).load do
  before "multistage:ensure" do
    set :stage, "_buffet" if ARGV.all? { |arg| arg.start_with?("buffet:") }
  end

  task :install_rvm, :roles => :install_rvm do
    run "echo Install rvm: `hostname`", shell: rvm_install_shell
    find_and_execute_task "rvm:install_rvm"
  end

  task :install_ruby, :roles => :install_ruby do
    run "echo Install ruby: `hostname`", shell: rvm_install_shell
    find_and_execute_task "rvm:install_ruby"
  end

  namespace :buffet do
    task :prepare do
      raise "buffet.yml was not found in current directory" unless File.exists?("buffet.yml")

      Buffet::Settings.load_file("buffet.yml")

      set :rvm_ruby_string, Buffet::Settings['rvm_ruby_string']
      Buffet::Settings.slaves.each do |s|
        server s.host, :buffet, :user => s.user
      end

      ruby_version, gem_set = rvm_ruby_string.split("@")
      gem_set &&= "@#{gem_set}"
      ruby_version = ruby_version.gsub('.', "\\\\.")

      need_install_rvm = false
      run("if [ -d $HOME/.rvm ]; then echo 1; else echo 0; fi", :shell => rvm_install_shell) do |channel, _, data|
        unless data.chomp == "1"
          server channel[:host], :install_rvm, :user => channel[:user]
          need_install_rvm = true
        end
      end
      install_rvm if need_install_rvm

      need_install_ruby = false
      run("(rvm list gemsets | grep -e \"#{ruby_version}.*#{gem_set}\") || echo 0", :shell => rvm_install_shell) do |channel, _, data|
        if data.chomp == "0"
          need_install_ruby = true
          server channel[:host], :install_ruby, :user => channel[:user]
        end
      end
      install_ruby if need_install_ruby
    end
  end
end
