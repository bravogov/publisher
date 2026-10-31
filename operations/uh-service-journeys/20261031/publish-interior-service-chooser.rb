require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="check-citizenship-or-immigration-service"
raise "Check existing publisher record before write" if Artefact.exists?(slug:slug)
body=<<~GOVSPEAK
  Use this checker to identify the correct Interior Office process for an enquiry or application about United Hampshire Citizenship, British nationality, entry permission, residence, settlement or an existing status record.

  The checker does not decide eligibility, grant citizenship or immigration status, or register an application. The Interior Office's Immigration and Citizenship Service maintains the authoritative status and casework records. United Hampshire Visas and Immigration performs the visa and immigration casework allocated to it.

  A Roblox or Discord account does not itself establish citizenship, residence, settlement or immigration permission.

  Public forms are made available individually after their receiving, statutory decision, correspondence and staff-access arrangements have been accepted.
GOVSPEAK
a=Artefact.new(name:"Check which citizenship or immigration service to use",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
raise "Missing content record" unless a.persisted?
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Select what you need to do and find the relevant Interior Office application or status service.",body:body)
raise "Invalid draft" unless e&.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish failed" unless e.reload.published?
PublishService.call(e)
puts "CHOOSER_PUBLISHED #{a.content_id}"
