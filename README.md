# cloudflup

Cloudflup is another Cloudflare dynamic DNS update client for A and AAAA records. That's pretty much it. By default, it will attempt to do both. If you don't care about AAAA, just comment out the call to its update method at the bottom.

### Usage
```$ ./cloudflup.rb```

### Configuration

Prior to running, make sure options.yaml is filled out. All parameters are required. You can get your API key from within your Cloudflare account.

License
---
MIT
