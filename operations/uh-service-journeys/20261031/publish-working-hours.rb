require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="check-working-hours-and-breaks"
raise "Existing record needs review" if Artefact.exists?(slug:slug)
body=<<~GOVSPEAK
  Use this interactive service to enter working hours and rest breaks and compare them with the relevant working-time information.

  For England, the calculator uses the established United Kingdom Working Time Regulations: the ordinary 48-hour average over 17 weeks for adults, young-worker 8-hour daily and 40-hour weekly limits, and ordinary minimum rest breaks. Exceptions, working patterns and contractual terms may change the result.

  Havenstead public-service and voluntary-work arrangements are assessed under the relevant United Hampshire rules, roles and procedures; UK limits are not automatically applied as legislation in that separate jurisdiction.

  The checker does not collect or store your identity, receive an employment complaint, adjudicate a dispute or determine an entitlement. Acas and the Health and Safety Executive have separate assigned functions.
GOVSPEAK
a=Artefact.new(name:"Check working hours and rest breaks",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
raise "Missing record" unless a.persisted?
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Enter your working hours, longest shift and rest breaks to check the relevant guidance.",body:body)
raise "Invalid draft" unless e&.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish failed" unless e.reload.published?
PublishService.call(e)
puts "HOURS_SERVICE_PUBLISHED #{a.content_id}"
