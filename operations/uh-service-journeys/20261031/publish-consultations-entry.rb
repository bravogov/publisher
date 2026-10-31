require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="respond-to-a-government-consultation"
if Artefact.exists?(slug:slug)
  puts "EXISTING_PUBLICATION_REQUIRES_REVIEW #{slug}"
  exit
end
body=<<~GOVSPEAK
  Government departments and public authorities may ask for views on proposed policies, services or changes to the law.

  ## Find a consultation

  [Search open government consultations](https://www.gov.uhrblx.com/search/policy-papers-and-consultations?content_store_document_type=open_consultations).

  Each consultation should explain:

  * what the authority is proposing and why
  * who can respond
  * how to send your views
  * the closing date

  If there are no open consultations, there is nothing to respond to at present. You can check again later.

  ## Send a response

  Open the consultation you want to respond to and follow its published response instructions. Some consultations may offer an online form. Others may use a different correspondence route.

  A consultation response goes to the authority responsible for the consultation, not automatically to the Cabinet Office. Do not send a response using an unrelated GOV.UH form.

  ## Find the outcome

  After a consultation closes, the responsible authority should publish its response or explain the next steps.

  [Search policy papers and consultations](https://www.gov.uhrblx.com/search/policy-papers-and-consultations).
GOVSPEAK
a=Artefact.new(name:"Respond to a government consultation",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
raise "Missing artefact" unless a.persisted?
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Find a consultation and follow the instructions for submitting your views.",body:body)
raise "Wrong draft" unless e.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review state" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready state" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publish state" unless e.reload.published?
PublishService.call(e)
puts "CONSULTATIONS_START_PUBLISHED content_id=#{a.content_id}"
