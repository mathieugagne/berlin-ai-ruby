#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

# OptionParser is used to parse "--env" or "-e" command line arguments
# Env arguments are passed to the docker compose executable, not to the command *inside* the docker container
# Eg: bin/docker/rspec --env ENV_VAR=test --exclude-pattern "spec/system/**/*_spec.rb"
# ->: docker compose exec --env ENV_VAR=test runner bin/rspec --exclude-pattern spec/system/**/*_spec.rb
require "optparse"

class DockerCompose
  APP_ROOT = File.expand_path("..", __dir__)

  attr_accessor :env_vars, :silent

  def initialize
    @env_vars = []
    @silent = false

    parse_options
  end

  def system!(command:, options:, service:, command_line: nil)
    args = ARGV.map { |x| x.index(/\s/) ? "\"#{x}\"" : x }.join(" ") # Keep quoted args from command line
    command = "#{command} #{env_vars.join(" ")} #{options} #{service} #{command_line} #{args}".squeeze(" ")

    FileUtils.chdir(APP_ROOT) do
      $stdout.puts "docker compose #{command}" unless silent
      system("docker", "compose", *command.split) || abort("\n== Command #{command} failed ==")
    end
  end

  private

  def parse_options
    begin
      OptionParser.new do |opts|
        opts.on("-eENV", "--envENV") do |env|
          @env_vars << "--env #{env}" # Add parsed env arguments to docker compose arguments
        end
        opts.on("-s", "--silent") do
          @silent = true
        end
        opts.on("-h", "--help") do
          help_message
        end
      end.order!(ARGV) # OptionParser will automatically remove parsed env arguments from ARGV
    rescue OptionParser::InvalidOption => e
      $ARGV.unshift(e.to_s.sub(/invalid option:\s+/, "")) # first unknown argument will be removed, put it back in the ARGV
    end
  end

  def help_message
    script_name = caller.last.split(":").first
    $stdout.puts <<~HELP
      Usage: #{script_name} [options] COMMAND

      Options:
        -h, --help        Show help
        -e, --env KEY=VAL Set environment variables (can be used multiple times)
        -s, --silent      Don't print the command being executed
    HELP
    abort
  end

  class << self
    def exec(service:, options: "", command_line: nil)
      new.system!(command: "exec", options: options, service: service, command_line: command_line)
    end

    def run(service:, options: "", command_line: nil)
      new.system!(command: "run", options: options, service: service, command_line: command_line)
    end
  end
end
