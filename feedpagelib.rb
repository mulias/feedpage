require 'feedjira'
require 'fileutils'
require 'erb'
require 'yaml'

# fetch rss content, build page, and handle errors
def new_feedpage url_list, template, html_out, required_fields, feeds_proc, log: nil
  begin
    check_file_exists(template)
    check_file_exists(url_list)
    urls = YAML.load_file(url_list)
    rss_content = process_feeds(urls, required_fields, feeds_proc, log)
    build_and_save_page(rss_content, template, html_out)
  rescue Exception => e
    debug(log, e.message)
    raise e
  end
end

private

def debug log, message
  puts message
  open(log, 'a') { |f| f.puts "#{Time.now}\t#{message}" } if log
end

# throw exception if file doesn't exist
def check_file_exists file
  raise "No such file #{file}" unless File.exists? file
end

# Get needed rss content from feed urls. Fetch the content with feedjira,
# filter out all feeds missing information, and apply the user defined
# feed content proc to collect the needed fields.
def process_feeds urls, required_fields, feeds_proc, log
  feeds = urls.map { |url| [url, Feedjira::Feed.fetch_and_parse(url)] }
  complete_feeds = feeds.select do |url, feed|
    required_fields.map do |field_name| 
      call_res = field_name.split('.').inject(feed) do |acc, subfield|
        acc.respond_to?(subfield) ? acc.send(subfield.to_sym) : nil
      end
      debug(log, "#{url} missing field '#{field_name}'") if call_res.nil?
      call_res
    end
    .none? { |field| field.nil? }
  end
  .map { |_, feed| feed } 
  feeds_proc.call(complete_feeds)
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
