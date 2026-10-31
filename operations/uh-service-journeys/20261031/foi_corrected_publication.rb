# Correct the existing live FOI guide through native Publisher, preserving history.
a = Artefact.find_by!(slug: "make-a-freedom-of-information-request")
p = Edition.where(panopticon_id:a.id,state:"published").order(version_number: :desc).first!
raise "Unexpected source" unless p.version_number == 5 && p.editionable.is_a?(AnswerEdition)
body = p.editionable.body
start_at = body.index("## How to make a request")
finish_at = body.index("## When you will get a response")
raise "Unexpected content structure" unless start_at && finish_at && start_at < finish_at
raise "Expected restriction absent" unless body[start_at...finish_at].include?("your registered UH Name")
section = <<~CONTENT
  ## How to make a request

  Make a recorded request to the public authority that holds the information. Include:

  * your name, or your registered UH Name if you have one
  * an address or other accepted electronic means for correspondence
  * a clear description of the recorded information you want

  You do not need United Hampshire Citizenship or United Hampshire registration to request information. You do not need a Roblox or Discord account.

  If you are registered, an authority may use your recorded UH Name and verified linked account identifiers where they are relevant to identifying your existing record. This is not a condition for making an information request.

  You can make your request electronically. An applicant does not need to provide a physical postal address or telephone number where an accepted electronic correspondence route is available.

  Use the authority's published information request or contact service. Where its dedicated FOI form is not yet available, use an accepted recorded contact route. The authority remains responsible for its reply, including any lawful refusal, internal review and Information Commissioner complaint information.

  If you need help, contact the authority using its published digital assistance route.

CONTENT
updated = body[0...start_at] + section + body[finish_at..-1]
actor = User.find_by!(name:"Eeth")
e = actor.new_version(p)
raise "Draft creation failed" unless e&.persisted? && e.reload.state=="draft"
e.editionable.update!(body:updated)
e.update!(change_note:"Correct applicant eligibility and identity wording under section 7 of the Freedom of Information Act 2026.")
actor.progress(e,request_type:"request_review")
raise "Review transition failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready transition failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publication transition failed" unless e.reload.published?
PublishService.call(e)
puts "FOI_CORRECTED_PUBLICATION version=#{e.version_number} content_id=#{a.content_id}"
