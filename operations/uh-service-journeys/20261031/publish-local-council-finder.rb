require "securerandom"
actor=User.find_by!(name:"Eeth")
slug="find-local-council"
raise "Existing artefact must be reviewed" if Artefact.exists?(slug:slug)
body=<<~GOVSPEAK
  Use the local council finder to select one of Havenstead's recognised local areas and the service you need.

  The service identifies the council corresponding to the area and tells you whether that council has commenced operations. It links to the council's website where there is an operating council service.

  Havenstead's initial operating local councils are Alderstead Council, Brightmere Council and Stonehaven Council. Rosehaven Council, Bridgewell Council and Greenhaven Council are recognised but have not commenced operations.

  Selecting an area is for finding public services. It does not register your address, determine your ward or make an application.

  England has separate local government arrangements. Do not use a Havenstead area result to determine the council responsible for an England address.
GOVSPEAK
a=Artefact.new(name:"Find your local council",slug:slug,kind:"answer",language:"en",state:"draft",content_id:SecureRandom.uuid,owning_app:"publisher")
a.save_as(actor)
raise "Artefact missing" unless a.persisted?
e=actor.create_edition(:answer,panopticon_id:a.id,slug:slug,title:a.name,assigned_to_id:actor.id,overview:"Choose a Havenstead local area to find the council responsible for local services and check whether it is operating.",body:body)
raise "Draft missing" unless e&.persisted? && e.state=="draft"
actor.progress(e,request_type:"request_review")
raise "Review transition failed" unless e.reload.in_review?
actor.progress(e,request_type:"skip_review")
raise "Ready transition failed" unless e.reload.state=="ready"
UpdateService.call(e)
actor.progress(e,request_type:"publish")
raise "Publication failed" unless e.reload.published?
PublishService.call(e)
puts "COUNCIL_FINDER_ROUTE_PUBLISHED content_id=#{a.content_id} version=#{e.version_number}"
