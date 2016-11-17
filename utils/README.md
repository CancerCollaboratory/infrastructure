## Glance image refresh script

## What does this script do?
* Check for new cloud images for various distributions (Ubuntu, CentOS, Debian)
* Alert Cloud admins via email when a new image is available
* Perform checksums along the way to ensure valid images are being downloaded
* Maintain a friendly and consistent image name in OpenStack (ie "CentOS 7 - latest") so users of the cloud can use predictable names in their automated workflows.
* Log script output to a file that is handled by logstash
* By default run as a check & notifier via cron but be able to run interactively to update with added syntax (--update)
