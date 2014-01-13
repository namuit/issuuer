#!/usr/bin/ruby
require 'open-uri'
require 'rubygems'
require 'json'
require 'rest-client'
require 'nokogiri' 

$PUB=""
$PAGES=300
if ARGV[0].include? "embed"
  document_id = ARGV[0].match /#(.++)/
  document_id = document_id.to_s
  document_id[0] = ""
  json_ip_url = "http://embed.issuu.com/" + document_id.to_s + ".jsonp"
  puts json_ip_url

  json_issuu = RestClient.get(json_ip_url).match /(\{.*\})/m

  issue_details = JSON.parse(json_issuu.to_s)

  $PUB=issue_details["id"]
  PUB_NAME = issue_details['dn']
else
  page = Nokogiri::HTML(open(ARGV[0]))  
  elements = page.search("script")
  for element in elements
  	if element.text.include? "window.issuuDataCache"
  	  json_issuu = element.text.match /{([\S\s]*)}/
  	  issue_details = JSON.parse(json_issuu.to_s)
  	  for single_node in issue_details['apiCache']
        for single_node_1 in single_node
          unless  single_node_1['document'].nil?
            $PUB = single_node_1['document']['documentId'].to_s
            PUB_NAME = single_node_1['document']['name'].to_s
            $PAGES = single_node_1['document']['pageCount'].to_i
            break
          end 
        end
  	  end
  	end
  end
end

directory_name = Dir::pwd + "/" + PUB_NAME

begin
  Dir::mkdir(directory_name)
rescue
  puts "the directory already exists"
end
 
for $X in 1..$PAGES do
  $PX="page_#{$X}.jpg"
  $PADX= directory_name + "/" + "page_#{"%03d" % $X}.jpg"
  puts(Time.now.strftime('%Y-%m-%d %X') +" get "+ $PX +" -> "+ $PADX)
  begin
    open($PADX,"wb").write(open("http://image.issuu.com/#{$PUB}/jpg/#{$PX}").read)
  rescue => e
    case e
      when OpenURI::HTTPError
        File.delete($PADX)
        break
      when SocketError
        # errore di socket
      else
        raise e
      end
    end
end
puts("#{Time.now.strftime('%Y-%m-%d %X')} DONE")
