require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="find-an-open-government-consultation"
a=Artefact.find_by(slug:slug)
if a
 raise "Unexpected existing type" unless a.kind=="transaction"
 puts "EXISTING_TRANSACTION #{a.content_id}"
 exit
end
url="https://www.gov.uhrblx.com/search/policy-papers-and-consultations?content_store_document_type=open_consultations"
a=Artefact.new(name:"Find an open government consultation",slug:slug,kind:"transaction",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
e=actor.create_edition(:transaction,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,
 overview:"Search consultations that are open for responses.",
 link:url,start_button_text:"Find open consultations",
 introduction:"Government departments and public authorities consult on proposed changes. Search for a consultation to see whether you can respond and when it closes.",
 need_to_know:"You do not need an account to search published consultations. Each consultation states how to respond.",
 more_information:"## Before you respond\n\nOpen the consultation and read the proposals, closing date and instructions. The responsible authority decides how responses are received. Only use the form or response method published for that consultation.\n\nIf no open consultations are listed, there is no current response form to complete.\n\nYou can also [read about responding to a government consultation](https://www.gov.uhrblx.com/respond-to-a-government-consultation).",
 alternate_methods:"",
 will_continue_on:"GOV.UH consultation search")
raise "Draft not created" unless e.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish failed" unless e.reload.published?
PublishService.call(e)
puts "CONSULTATION_TRANSACTION_LIVE #{a.content_id}"
