#!/usr/bin/env ruby

require "rubygems"
require "commander/import"
require "byebug"

require "./google_sheet"

program :name, "cleaner"
program :version, "0.0.1"
program :description, "A program to clean up the COVID-19 IFCN Data Set"

command :clean do |c|
  c.syntax = "cleaner clean <google_sheets_id> [options]"
  c.summary = ""
  c.description = ""
  c.example "Run the cleaner", "clean <google-sheet-id>"
  c.action do |args, options|
    google_sheets_id = args.first
    if google_sheets_id.nil?
      puts "No google sheet id found"
      exit
    end

    google_sheet_manager = GoogleSheetManager.new(google_sheets_id)
    google_sheet_manager.process
  end
end

default_command :clean
