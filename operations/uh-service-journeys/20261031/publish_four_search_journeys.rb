# Native GOV.UH Publisher transactions for existing operating search and directory services.
require "json"
require "securerandom"
items = JSON.parse(<<~'PAYLOAD')
[
  {
    "slug": "find-a-united-hampshire-government-organisation",
    "title": "Find a United Hampshire government organisation",
    "overview": "Find a government department, office, agency or public body and see its responsibilities.",
    "link": "https://www.gov.uhrblx.com/government/organisations",
    "start_button_text": "Find an organisation",
    "introduction": "Use the government organisations directory to find a department, office, executive agency or public body. Organisation pages explain responsibilities and may provide official contact and publication links.",
    "need_to_know": "You do not need a United Hampshire account to search the public directory.",
    "more_information": "## Before you start\n\nSearch by the name of an organisation or browse the directory. England Government, local authorities, Parliament and the Judiciary have their own responsibilities. Use the contact routes published by the organisation responsible for your enquiry.\n\n## If you need to send a request\n\nChoose the relevant public authority's service or contact route. The directory itself does not submit an application or complaint.",
    "alternate_methods": "",
    "will_continue_on": "GOV.UH organisation directory"
  },
  {
    "slug": "find-a-united-hampshire-minister",
    "title": "Find a United Hampshire minister",
    "overview": "Find current Government ministers and the offices and responsibilities shown in the ministerial directory.",
    "link": "https://www.gov.uhrblx.com/government/ministers",
    "start_button_text": "Find a minister",
    "introduction": "Use the published list of Government ministers to identify an office-holder and the department or ministerial responsibility associated with their office.",
    "need_to_know": "You do not need a United Hampshire account to view the public ministerial directory.",
    "more_information": "## Ministerial responsibilities\n\nCheck the minister's current departmental or office profile before directing correspondence. Ministers do not perform the statutory functions of Parliament, the Judiciary or independent public authorities.\n\n## Contacting a department\n\nUse the relevant organisation's published contact or application route. The ministerial directory does not itself send correspondence.",
    "alternate_methods": "",
    "will_continue_on": "GOV.UH ministers directory"
  },
  {
    "slug": "search-united-hampshire-legislation",
    "title": "Search United Hampshire legislation",
    "overview": "Find United Hampshire Acts and other legislation by title, year or number.",
    "link": "https://legislation.gov.uhrblx.com/search/",
    "start_button_text": "Search legislation",
    "introduction": "Search the United Hampshire legislation website for laws by title, year or number. Open a result to read the legislation and check its recorded status.",
    "need_to_know": "You can search without signing in. Search results and historic texts should not be confused with evidence that a provision is currently in force.",
    "more_information": "## Before you start\n\nIf you know the year, title or chapter number, enter it in the search form. Check the publication and commencement details of the result where available.\n\nThe legislation website is the relevant official service for viewing Acts. It is not an application service for legal advice or a court case.",
    "alternate_methods": "",
    "will_continue_on": "United Hampshire legislation website"
  },
  {
    "slug": "search-government-publications-and-guidance",
    "title": "Search government publications and guidance",
    "overview": "Search published GOV.UH information, Government publications and guidance by keyword.",
    "link": "https://www.gov.uhrblx.com/search/all",
    "start_button_text": "Search GOV.UH",
    "introduction": "Use GOV.UH search to find published guidance, reports, policies, services and Government information. Enter keywords and use the available filters to narrow the results.",
    "need_to_know": "The search is public and does not require an account. Restricted or unpublished material is not accessible through the public search.",
    "more_information": "## What you can search\n\nSearch for a subject, organisation, law or service. The results can take you to GOV.UH guidance and official publications.\n\nFor recorded information not already published, see [Make a freedom of information request](https://www.gov.uhrblx.com/make-a-freedom-of-information-request).",
    "alternate_methods": "",
    "will_continue_on": "GOV.UH search"
  }
]
PAYLOAD
actor = User.find_by!(name:"Eeth")
items.each do |x|
  slug=x.fetch("slug")
  a=Artefact.find_by(slug:slug)
  raise "Existing artefact has different type: #{slug}" if a && a.kind!="transaction"
  unless a
    a=Artefact.new(name:x.fetch("title"),slug:slug,kind:"transaction",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
    a.save_as(actor)
  end
  e=Edition.where(panopticon_id:a.id).order(version_number: :desc).first
  if e&.published?
    raise "Existing published destination differs" unless e.editionable.link==x.fetch("link")
    puts "ALREADY_PUBLISHED #{slug} #{a.content_id}"
    next
  end
  unless e
    e=actor.create_edition(:transaction,panopticon_id:a.id,slug:slug,title:x.fetch("title"),assigned_to_id:actor.id,overview:x.fetch("overview"),link:x.fetch("link"),start_button_text:x.fetch("start_button_text"),introduction:x.fetch("introduction"),need_to_know:x.fetch("need_to_know"),more_information:x.fetch("more_information"),alternate_methods:x.fetch("alternate_methods"),will_continue_on:x.fetch("will_continue_on"))
  end
  raise "Draft missing for #{slug}" unless e&.reload&.state=="draft"
  raise "Target changed for #{slug}" unless e.editionable.link==x.fetch("link")
  actor.progress(e,request_type:"request_review")
  raise "Review failed" unless e.reload.in_review?
  actor.progress(e,request_type:"skip_review")
  raise "Ready failed" unless e.reload.state=="ready"
  UpdateService.call(e)
  actor.progress(e,request_type:"publish")
  raise "Publish failed" unless e.reload.published?
  PublishService.call(e)
  puts "PUBLISHED_TRANSACTION #{slug} #{a.content_id} edition=#{e.version_number}"
end
