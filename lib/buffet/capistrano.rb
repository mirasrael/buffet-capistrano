require "buffet"
require "rvm"
require "rvm/capistrano"

Capistrano::Configuration.instance(true).load do
  before "multistage:ensure" do
    set :stage, "_buffet" if ARGV.all? { |arg| arg.start_with?("buffet:") }
  end

  namespace :buffet do
    def run_when(command, role, opts = {})
      servers = []
      run(command, opts) do |channel, _, data|
        servers << "#{channel[:server].user}@#{channel[:host]}" if data.chomp == "0"
      end
      unless servers.empty?
        servers.each { |s| server s, role }
        with_env "ROLES", role.to_s do
          yield
        end
      end
    end

    task :upload_project, :roles => :buffet do
      run "mkdir -p #{File.dirname(buffet_workspace_directory)}"
      servers = find_servers_for_task current_task
      servers.each do |server|
        run_locally "rsync --exclude=.git --exclude=log -r --delete -L --safe-links ./ #{server}:/home/#{server.user || Capistrano::ServerDefinition.default_user}/#{buffet_workspace_directory}/"
      end
    end

    task :load_config do
      raise "buffet.yml was not found in current directory" unless File.exists?("buffet.yml")

      Buffet::Settings.load_file("buffet.yml")
      Buffet::Settings.slaves.each do |s|
        server s.host, :buffet, :user => s.user
      end
      set :buffet_workspace_directory, "#{Buffet::Settings.project.directory_on_slave}"
    end

    task :install_rvm, :roles => :buffet do
      run_when "if [ -d $HOME/.rvm ]; then echo 1; else echo 0; fi", :install_rvm, :roles => :buffet, :shell => rvm_install_shell do
        rvm.install_rvm
      end
    end

    task :install_ruby, :roles => :buffet do
      set :rvm_ruby_string, Buffet::Settings['rvm_ruby_string']
      ruby_version, gem_set = rvm_ruby_string.split("@")
      gem_set &&= "@#{gem_set}"
      ruby_version = ruby_version.gsub('.', "\\.")
      run_when "(rvm list gemsets | grep -e #{ruby_version}.*#{gem_set}) || echo 0", :install_ruby, :roles => :buffet do
        install_ruby
      end
    end

    task :prepare, :roles => :buffet do
      install_rvm
      install_ruby
    end

    before 'buffet:prepare', 'buffet:load_config', 'buffet:upload_project'
  end
end
