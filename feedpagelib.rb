require 'feedjira'
require 'fileutils'
require 'erb'
require 'yaml'

def new_feedpage url_list, template, html_out, raise_error: true, log: nil
  begin
    check_file_exists(template)
    check_file_exists(url_list)
    urls = YAML.load_file(url_list)
    build_and_save_page(urls, template, html_out)
  rescue Exception => e
    open(log, 'a') { |f| f.puts "#{Time.now}\t#{e.message}" } if log
    raise e if raise_error
  end
end

private

def check_file_exists file
  raise "No such file #{file}" unless File.exists? file
end

def build_and_save_page urls, template, html_out

  # get content
  @feeds = urls.map { |url| Feedjira::Feed.fetch_and_parse(url) }

  # intermediary file names
  html_out_new = html_out + '.new'
  html_out_backup  = html_out + '.backup'

  # save to temp file
  template_file = File.open(template, 'rb')
  html_out_new_file = File.open(html_out_new, 'w')
  output = ERB.new(template_file.read).result(binding)
  html_out_new_file.write(output)
  template_file.close
  html_out_new_file.close

  # move to final file
  FileUtils.touch html_out
  FileUtils.mv html_out, html_out_backup
  FileUtils.mv html_out_new, html_out
end
