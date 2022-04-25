/confidential
/label ~"group::product intelligence" ~"devops::growth" ~backend ~"section::growth" ~"Category:Service Ping"
/epic https://gitlab.com/groups/gitlab-org/-/epics/6000
/weight 5
/title Monitor and Generate GitLab.com Service Ping

<!-- This is issue template used by https://about.gitlab.com/handbook/engineering/development/growth/product-intelligence/ for tracking effort around Service Ping reporting for GitLab.com -->

[Product Intelligence group](https://about.gitlab.com/handbook/engineering/development/growth/product-intelligence/) runs manual reporting of ServicePing for the gitlab.com on weekly basis. This issue captures work required to complete reporting process and follow up chores focused on verification of performance of metrics and identify any potential issues.

## New metrics to be verified

<!-- Add new metrics added during previous milestone that needs to be verified -->

## Failed metrics

Broken metrics issues are marked with ~"broken metric" label

## How to generate Service Ping for GtiLab.com

### Through detached screen session

#### Prerequisites

1. make sure the key is added to the ssh agent locally
   `ssh-add `

#### Triggering

1. Run `ssh-add` to add the key to the agent
1. Connect to bastion with agent forwarding `$ ssh -A lb-bastion.gprd.gitlab.com `
1. Note which bastion host machine was assigned eg: `<username>@bastion-01-inf-gprd.c.gitlab-production.internal:~$ ` mean you got connected to `bastion-01-inf-gprd.c.gitlab-production.internal`
1. Create named screen `$ screen -S $USER-service-ping-$(date +%F)`
1. Connect to console host `$ ssh $USER-rails@console-01-sv-gprd.c.gitlab-production.internal`
1. Run `ServicePing::SubmitService.new.execute`
1. Detach from screen `ctrl + a, ctrl + d`
1. Exit from bastion `$ exit`

#### Verification (After approx 30 hours)

1. Reconnect to bastion `$ ssh -A lb-bastion.gprd.gitlab.com `. Because there are many host machines serving as bastions, make sure that you got connected to the same host machine that ServicePing was started on, or connect directly to the same machine eg: `$ ssh bastion-01-inf-gprd.c.gitlab-production.internal`
1. Find your screen session `$ screen -ls`
1. Attach to your screen session `$ screen -x 14226.mwawrzyniak_service_ping_2021_01_22`
1. Check the last payload in `raw_usage_data` table: `RawUsageData.last.payload`
1. Check the when the payload was sent `RawUsageData.last.sent_at`

#### Stop Service Ping process

1. Reconnect to bastion host machine eg: `$ ssh bastion-01-inf-gprd.c.gitlab-production.internal`
1. Find your screen session `$ screen -ls`
1. Attach to your screen session `$ sudo -u <username> screen -r`
1. Stop process `ctrl +c`

OR

1. Reconnect to bastion host machine eg: `$ ssh bastion-01-inf-gprd.c.gitlab-production.internal`
1. List all process started by your user eg: `$ ps faux | grep <username>`
1. Locate one owning ServicePing reporting
1. Send kill signal `kill -9 <service_ping_pid>`

### Service Ping process triggering (through long running ssh session)

1. Connect to  `gprd` rails console
1. Run `SubmitUsagePingService.new.execute` this will take more than 30 hours.
1. Check the last payload in `raw_usage_data` table: `RawUsageData.last.payload`
1. Check the when the payload was sent `RawUsageData.last.sent_at`

```
ServicePing::SubmitService.new.execute

# Get the payload
RawUsageData.last.payload

# Time when payload was sent to VersionsAppp
RawUsageData.last.sent_at
```

## How to check Service Ping in VersionsApp

In order to verify if ServicePing was received at VersionsApp follow steps:

1. In versions app console RawUsageData.find(uuid: '')
1. In Rails console, check the related `RawUsageData` object
1. Or in VersionsApp UI https://version.gitlab.com/usage_data/usage_data_id

```ruby

/bin/herokuish procfile exec rails console

puts UsageData.select(:recorded_at, :app_server_type).where(hostname: 'gitlab.com', uuid: 'ea8bf810-1d6f-4a6a-b4fd-93e8cbd8b57f').order('id desc').limit(5).to_json

puts UsageData.find(21635202).raw_usage_data.payload.to_json
```

## Monitoring events tracked using Redis HLL

Trigger some events from UI

```ruby
Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'event_name', start_date: 28.days.ago, end_date: Date.current) 
```

### What to do if you get mentioned?

In this issue, we keep the track of new metrics added to service ping and metrics that are timing out.

If you get mentioned please check the failing metric and open an optimization issue.

### Service Ping manual generation for GitLab.com schedule

| Generation start date | developer GitLab handle | Link to comment with payload
| ------ | ------ | ----- |
| 2022-04-18 |    |     |
| 2022-04-25 |  |  |
| 2022-05-02 |  |   |
| 2022-05-09 |   | |
| 2022-05-16 | |  |
