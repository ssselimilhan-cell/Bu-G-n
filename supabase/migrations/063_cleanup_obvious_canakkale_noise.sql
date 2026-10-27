-- Deactivate obvious non-destination / duplicate-noise records in Çanakkale.
update public.places set is_active=false where city='Çanakkale' and slug='osm-node-13886633101'; -- bicycle platform, not a visitor destination
update public.places set is_active=false where city='Çanakkale' and slug='osm-node-4199088289'; -- ferry label, not a destination
update public.places set is_active=false where city='Çanakkale' and slug='osm-node-10777031907'; -- English free-camp note
update public.places set is_active=false where city='Çanakkale' and slug='osm-way-183603236'; -- duplicate/alternate spelling of Abydos
update public.places set is_active=false where city='Çanakkale' and slug='osm-node-6700770146'; -- English label for Tevfikiye Culture and Art Center