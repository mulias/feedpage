require 'feedjira'
require 'fileutils'
require 'erb'
require 'yaml'

# fetch rss content, build page, and handle errors
def new_feedpage url_list, template, html_out, feeds_proc, raise_error: true, log: nil
  begin
    check_file_exists(template)
    check_file_exists(url_list)
    urls = YAML.load_file(url_list)
    rss_content = process_feeds(urls, feeds_proc)
    build_and_save_page(rss_content, template, html_out)
  rescue Exception => e
    open(log, 'a') { |f| f.puts "#{Time.now}\t#{e.message}" } if log
    raise e if raise_error
  end
end

private

# throw exception if file doesn't exist
def check_file_exists file
  raise "No such file #{file}" unless File.exists? file
end

# get needed rss content from feed urls
def process_feeds urls, feeds_proc
  all_feeds = urls.map { |url| Feedjira::Feed.fetch_and_parse(url) }
  feeds_proc.call(all_feeds)
end

# build html from template, save to file
def build_and_save_page rss_content, template, html_out
  # save feed content to a variable accessable from erb file
  @rss_content = rss_content
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
