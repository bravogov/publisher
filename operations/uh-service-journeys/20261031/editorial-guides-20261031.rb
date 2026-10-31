actor = User.find_by!(name: "Eeth")
edits = {
  "using-public-services" => [
    ["Choose the subject that best describes what you want to do. Each page gives information about the service and links to related guidance.", <<~TEXT.strip],
      Choose a subject to find information, check eligibility or start an application.

      You can also:

      * [find your local council](https://www.gov.uhrblx.com/find-local-council)
      * [check which citizenship or immigration service to use](https://www.gov.uhrblx.com/check-citizenship-or-immigration-service)
      * [check working hours and rest breaks](https://www.gov.uhrblx.com/check-working-hours-and-breaks)
    TEXT
    ["You can also [find a government department or public body]", "If you need to contact a public authority, [find a government department or public body]"]
  ],
  "employment-rights-and-employer-responsibilities" => [
    ["The Department for Work and Skills develops employment policy in Havenstead. Acas, the Fair Work Agency and the Health and Safety Executive have their own functions. Check the organisation's published guidance before submitting a complaint.", <<~TEXT.strip],
      You can [check working hours and rest breaks](https://www.gov.uhrblx.com/check-working-hours-and-breaks) for guidance on usual limits and minimum breaks.

      For advice about a workplace dispute or conciliation, see [Acas](https://www.gov.uhrblx.com/government/organisations/acas). To report a workplace health and safety concern, see the [Health and Safety Executive](https://www.gov.uhrblx.com/government/organisations/health-and-safety-executive).

      The Department for Work and Skills is responsible for Havenstead employment policy. It does not decide individual employment disputes.
    TEXT
  ],
  "find-your-council-and-local-services" => [
    ["## Find an organisation\n\nUse the [government organisations directory](https://www.gov.uhrblx.com/government/organisations) to find the authority responsible for the service. Check its contact information before sending an application or complaint.", <<~TEXT.strip],
      ## Find your council

      [Find your local council](https://www.gov.uhrblx.com/find-local-council) lets you choose a Havenstead local area and find out whether its council is operating.

      For services in England, check the relevant council or public authority. You can [find a government organisation](https://www.gov.uhrblx.com/government/organisations) if you are not sure which body provides the service.
    TEXT
  ],
  "citizenship-status-and-participation" => [
    ["If you think a citizenship record is wrong, contact the Interior Office through its published status enquiry procedure. Include the information needed to identify the record. A change to your username or platform role does not establish a change in citizenship.", <<~TEXT.strip],
      [Check which citizenship or immigration service to use](https://www.gov.uhrblx.com/check-citizenship-or-immigration-service) to find the route for a record correction or evidence of citizenship.

      The online forms for these requests are not yet open. For help, see the [Interior Office](https://www.gov.uhrblx.com/government/organisations/interior-office).

      Changing your username or platform role does not change your citizenship.
    TEXT
  ],
  "visas-entry-clearance-and-citizenship" => [
    ["The Interior Office administers immigration permission and citizenship matters for Havenstead. The correct application depends on your status and why you want to enter or stay.", <<~TEXT.strip],
      The Interior Office administers immigration permission and citizenship matters for Havenstead. Different applications cover entry, residence, settlement and citizenship.

      [Check which citizenship or immigration service to use](https://www.gov.uhrblx.com/check-citizenship-or-immigration-service) to find the relevant process.
    TEXT
    ["Check the relevant service's application guidance and evidence requirements. A decision notice should explain how to seek an administrative review or appeal where available.", "Check the application guidance and evidence requirements for your route. If you receive a decision, read the notice to find out whether you can ask for an administrative review or appeal."]
  ]
}
edits.each do |slug, replacements|
  a = Artefact.find_by!(slug: slug)
  p = Edition.where(panopticon_id: a.id, state: "published").order(version_number: :desc).first!
  raise "Unexpected edition type #{slug}" unless p.editionable.is_a?(AnswerEdition)
  body = p.editionable.body
  replacements.each do |old, new_text|
    raise "Unexpected content #{slug}" unless body.scan(old).size == 1
    body = body.sub(old, new_text)
  end
  e = actor.new_version(p)
  raise "Draft creation failed #{slug}" unless e&.persisted? && e.reload.state == "draft"
  e.editionable.update!(body: body)
  e.update!(change_note: "Editorial correction: clearer service instructions and working links.")
  actor.progress(e, request_type: "request_review")
  raise "Review failed #{slug}" unless e.reload.in_review?
  actor.progress(e, request_type: "skip_review")
  raise "Ready failed #{slug}" unless e.reload.state == "ready"
  UpdateService.call(e)
  actor.progress(e, request_type: "publish")
  raise "Publish failed #{slug}" unless e.reload.published?
  PublishService.call(e)
  puts "EDITORIAL_GUIDE_PUBLISHED #{slug} version=#{e.version_number} content_id=#{a.content_id}"
end
