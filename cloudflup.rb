#!/usr/bin/env ruby

# title:  cloudflup.rb
# descr:  just another cloudflare dynamic dns update client for A and AAAA records
# author: andrew o'neill
# date:   2017

require 'resolv'
require 'net/https'
require 'json'

email = ''
key = ''
zone = ''
record = ''
ip4_uri = 'http://whatismyip.akamai.com'
ip6_uri = 'http://ipv6.whatismyip.akamai.com'
cf_uri = 'https://api.cloudflare.com/client/v4/zones'

class Cloudflare
  def initialize(cf_uri, email, key, zone, record)
    @email = email
    @key = key
    @zone = zone
    @cf_uri = cf_uri
    @record = record
  end

  def make_request(params, uri, request, response)
    headers = {"X-Auth-Email" => @email, "X-Auth-Key" => @key, "Content-Type" => "application/json"}
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = eval(request)
    req.body = params.to_json
    resp = http.request(req)
    json = JSON.parse(resp.body)
    return eval(response)
  end

  def get_zone_id
    uri = URI.parse(@cf_uri)
    params = "name=#{@zone}"
    request = "Net::HTTP::Get.new(uri.path+'?'+params, headers)"
    response = "json.fetch('result').first['id']"
    make_request(params, uri, request, response)
  end

  def get_record_id(type)
    uri = URI.parse(@cf_uri+"/#{get_zone_id}/dns_records")
    params = "type=#{type}&name=#{@record}"
    request = "Net::HTTP::Get.new(uri.path+'?'+params, headers)"
    response = "json.fetch('result').first['id']"
    make_request(params, uri, request, response) 
  end

  def update(ip, type)
    uri = URI.parse(@cf_uri+"/#{get_zone_id}/dns_records/#{get_record_id(type)}")
    params = {"type":type,"name":@record,"content":ip}
    request = "Net::HTTP::Put.new(uri.path, headers)"
    response = "json['success']"
    make_request(params, uri, request, response)
  end
end

def get_ipv4(ip4_uri)
  ip4 = Net::HTTP.get(URI.parse(ip4_uri)).strip
  if !!(ip4 =~ Resolv::IPv4::Regex)
    return ip4
  else
    puts "Not a valid IPv4 address: #{ip4}"
    exit 1
  end
end

def get_ipv6(ip6_uri)
  ip6 = Net::HTTP.get(URI.parse(ip6_uri)).strip
  if !!(ip6 =~ Resolv::IPv6::Regex)
    return ip6
  else
    puts "Not a valid IPv6 address: #{ip6}"
    exit 1
  end
end

cloudflare = Cloudflare.new(cf_uri, email, key, zone, record)
cloudflare.update(get_ipv4(ip4_uri), 'A')
cloudflare.update(get_ipv6(ip6_uri), 'AAAA')
