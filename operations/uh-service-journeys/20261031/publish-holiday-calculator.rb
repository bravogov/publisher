require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="calculate-holiday-entitlement"
raise "Existing publication needs review" if Artefact.exists?(slug:slug)
body=<<~GOVSPEAK
  Calculate statutory paid annual leave for a regular-hours worker in England who works the same number of days each week for a full leave year.

  Most workers are entitled to 5.6 weeks of paid holiday a year, subject to a maximum of 28 days. Bank holidays may be included in this entitlement.

  This calculator does not apply to irregular-hours workers, part-year work, variable-length working days or Havenstead public-service and voluntary-work terms. Those arrangements require the appropriate calculation and rules.

  The calculator does not collect personal information or make an employment decision.
GOVSPEAK
a=Artefact.new(name:"Calculate holiday entitlement",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Calculate paid holiday entitlement for regular-hours work in England.",body:body)
raise "No draft" unless e.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Not in review" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Not ready" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish not completed" unless e.reload.published?
PublishService.call(e)
puts "HOLIDAY_CALCULATOR_PUBLISHED #{a.content_id}"
