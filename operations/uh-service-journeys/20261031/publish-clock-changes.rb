require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="when-do-the-clocks-change"
raise "Unexpected existing route" if Artefact.exists?(slug:slug)
body=<<~GOVSPEAK
  This public service gives the dates on which the clocks change in England.

  In England, clocks go forward one hour at 1am on the last Sunday in March. They go back one hour at 2am on the last Sunday in October.

  The service lets you select a year between 2025 and 2040 to see the relevant dates. No account is required.

  These are the established United Kingdom clock-change arrangements for England. This guidance does not purport to enact a separate time-zone arrangement for Havenstead.
GOVSPEAK
a=Artefact.new(name:"When do the clocks change?",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
raise "Missing content record" unless a.persisted?
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Choose a year to find when clocks go forward and back in England.",body:body)
raise "Invalid draft" unless e&.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish failed" unless e.reload.published?
PublishService.call(e)
puts "CLOCK_CHANGE_ROUTE_PUBLISHED id=#{a.content_id}"
