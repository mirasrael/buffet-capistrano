require "buffet"
require "rvm"
require "rvm/capistrano"

Capistrano::Configuration.instance(true).load do
  before "multistage:ensure" do
    set :stage, "_buffet" if ARGV.all? { |arg| arg.start_with?("buffet:") }
  end

  namespace :buffet do
    task :prepare do
      raise "buffet.yml was not found in current directory" unless File.exists?("buffet.yml")

      Buffet::Settings.load_file("buffet.yml")

      set :rvm_ruby_string, Buffet::Settings['rvm_ruby_string']
      Buffet::Settings.slaves.each do |slave|
        puts "install slave: #{slave.user_at_host}"

        server slave.host, :rvm, user: slave.user

        rvm.install_rvm unless capture("if [ -d $HOME/.rvm ]; then echo 1; else echo 0; fi").chomp == '1'
        rvm.install_ruby
      end
    end
  end
end
