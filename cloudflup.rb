#!/usr/bin/env ruby

# title:  cloudflup.rb
# descr:  just another cloudflare dynamic dns update client for A and AAAA records
# author: andrew o'neill
# date:   2017

require 'resolv'
require 'net/https'
require 'json'
require 'yaml'

class Cloudflare
  def initialize
    cnf = File.dirname(File.expand_path(__FILE__)) + '/options.yaml'
    opts = YAML.load_file(cnf)

    # load in params from config
    @email = opts['email']
    @key = opts['key']
    @zone = opts['zone']
    @cf_uri = opts['cf_uri']
    @record = opts['record']
    @ip4_uri = opts['ip4_uri']
    @ip6_uri = opts['ip6_uri']

    # make sure required params are set
    opts.each do |k, v|
      raise "The #{k} parameter is not set" if v.length == 0
    end
  end

  # get current public ipv4/6 address
  def get_ip(type)
    case type.downcase
    when 'a'
      print "Getting current public IPv4 address..."
      ip = Net::HTTP.get(URI.parse(@ip4_uri)).strip
      raise RuntimeError, "Not a valid IPv4 address: #{ip}" unless ip =~ Resolv::IPv4::Regex
    when 'aaaa'
      print "Getting current public IPv6 address..."
      ip = Net::HTTP.get(URI.parse(@ip6_uri)).strip
      raise RuntimeError, "Not a valid IPv6 address: #{ip}" unless ip =~ Resolv::IPv6::Regex
    else
      raise RuntimeError, "Invalid record type: #{type}"
    end
    puts "#{ip}...OK!"
    return ip
  end

  # perform REST calls against cloudflare api, including any params
  def make_request(params, uri, request, response)
    headers = {"X-Auth-Email" => @email, "X-Auth-Key" => @key, "Content-Type" => "application/json"}
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = eval(request)
    req.body = params.to_json
    resp = http.request(req)
    raise RuntimeError, resp.value if resp.code != '200'
    json = JSON.parse(resp.body)
    return eval(response)
  end

  # retrieve the zone id
  def get_zone_id
    uri = URI.parse(@cf_uri)
    params = "name=#{@zone}"
    request = "Net::HTTP::Get.new(uri.path+'?'+params, headers)"
    response = "json.fetch('result').first['id']"
    make_request(params, uri, request, response)
  end

  # retrieve the record id
  def get_record_id(type)
    uri = URI.parse(@cf_uri+"/#{get_zone_id}/dns_records")
    params = "type=#{type.upcase}&name=#{@record}"
    request = "Net::HTTP::Get.new(uri.path+'?'+params, headers)"
    response = "json.fetch('result').first['id']"
    make_request(params, uri, request, response) 
  end

  # perform the actual update against the specific record type
  def update(type)
    uri = URI.parse(@cf_uri+"/#{get_zone_id}/dns_records/#{get_record_id(type)}")
    params = {"type":type.upcase,"name":@record,"content":get_ip(type)}
    request = "Net::HTTP::Put.new(uri.path, headers)"
    response = "json['success']"
    print "Updating #{type} record..."
    make_request(params, uri, request, response)
    puts "OK!"
  end
end

cloudflare = Cloudflare.new
cloudflare.update('A')
cloudflare.update('AAAA')
