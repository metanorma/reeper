require 'erb'
# EXPRESS to UML 2 Mapping
# Version 0.1
#
# This function navigates the EXPRESS STEPMod Model Ruby Classes
# and performs a structural EXPRESS-to-UML2 (2.1.2) mapping using Ruby ERB templates.
# The output is in XMI 2.1 syntax.
# 
# Integer, Boolean, String -> UML equivalent builtin type
# Real, Number, Binary, Logical -> New PrimitiveType
# Schema -> Package
# Entity (subtype of) -> Class (Generalization)
# Select Type -> Interface and InterfaceRealization
# Enum Type -> Enumeration and EnumerationLiteral
# Explicit Attribute (Optional) Primitive or Enum -> Property owned by Class (with lower)
# Explicit Attribute (Optional) Entity -> Property owned by Class (with lower) plus Association owning other end property
#
#######################################################################################

def map_from_express( mapinput )

# datatypes for simple and aggregates of simple type
datatype_hash = Hash.new
datatype_hash["INTEGER"] = 'http://schema.omg.org/spec/UML/2.1.2/uml.xml#Integer'
# datatype_hash["REAL"] = 'http://www.w3.org/2001/XMLSchema#float'
# datatype_hash["NUMBER"] = 'http://www.w3.org/2001/XMLSchema#float'
# datatype_hash["BINARY"] = 'http://www.w3.org/2001/XMLSchema#hexBinary'
datatype_hash["BOOLEAN"] = 'http://schema.omg.org/spec/UML/2.1.2/uml.xml#Boolean'
# datatype_hash["LOGICAL"] = 'http://www.w3.org/2001/XMLSchema#boolean'
datatype_hash["STRING"] = 'http://schema.omg.org/spec/UML/2.1.2/uml.xml#String'

# XMI File Start Template
overall_start_template = %{<?xml version="1.0" encoding="UTF-8"?>
<uml:Model xmi:version = "2.1" xmlns:xmi = "http://schema.omg.org/spec/XMI/2.1" xmlns:uml = "http://schema.omg.org/spec/UML/2.1.2" name = "UMLfromEXPRESS" xmi:id = "_0">
<packagedElement xmi:type="uml:PrimitiveType" xmi:id="REAL" name="Real" />
<packagedElement xmi:type="uml:PrimitiveType" xmi:id="NUMBER" name="Number" />
<packagedElement xmi:type="uml:PrimitiveType" xmi:id="BINARY" name="Binary" />
<packagedElement xmi:type="uml:PrimitiveType" xmi:id="LOGICAL" name="Logical" />}

# XMI File End Template
overall_end_template = %{  </uml:Model>}

# SCHEMA Start Template
schema_start_template = %{<packagedElement xmi:type = "uml:Package" xmi:id = "_1_<%= schema.name %>" name = "<%= schema.name %>" visibility = "public">}

# SCHEMA End Template
schema_end_template = %{</packagedElement>}

# ENTITY Start Template
entity_start_template = %{<packagedElement xmi:type = "uml:Class" xmi:id = "<%= xmiid %>" name = "<%= entity.name %>" isAbstract = "FALSE" visibility = "public">}

# SUBTYPE OF Template
supertype_template = %{<generalization xmi:type="uml:Generalization" xmi:id="<%= xmiid %>" general="<%= xmiid_supertype %>"/>}

# ENTITY End Template
entity_end_template = %{</packagedElement>}

# ENUMERATION Start Template
enum_start_template = %{<packagedElement xmi:type = "uml:Enumeration" xmi:id = "<%= type_xmiid %>" name = "<%= enum.name %>">}

# ENUMERATION ITEM Template
enum_item_template = %{<ownedLiteral xmi:type="uml:EnumerationLiteral" xmi:id="<%= enumitem_xmiid %>" name="<%= enumitem %>" classifier="<%= type_xmiid %>" enumeration="<%= enumitem_xmiid %>">
<specification xmi:type="uml:LiteralInteger" xmi:id="<%= enumitem_xmiid + '_specification' %> "/>
</ownedLiteral>}

# ENUMERATION End Template
enum_end_template = %{</packagedElement>}

# SELECT Start Template
select_start_template = %{<packagedElement xmi:type = "uml:Interface" xmi:id = "<%= xmiid %>" name = "<%= select.name %>" isAbstract = "TRUE" visibility = "public">}

# SELECT ITEM IS ENTITY Template
selectitem_entity_template = %{ <interfaceRealization xmi:type="uml:InterfaceRealization" xmi:id="<%= xmiid %>" supplier="<%= xmiid_supplier %>" client="<%= xmiid_client %>" contract="<%= xmiid_supplier %>" implementingClassifier="<%= xmiid_client %>"/>}

# SELECT ITEM IS SELECT Template
selectitem_select_template = %{ <interfaceRealization xmi:type="uml:InterfaceRealization" xmi:id="<%= xmiid %>" supplier="<%= xmiid_supplier %>" client="<%= xmiid_client %>" contract="<%= xmiid_supplier %>" implementingClassifier="<%= xmiid_client %>"/>}

# SELECT End Template
select_end_template = %{</packagedElement>}

# Template covering abstract entity types
abstract_entity_template = %{}

# Template covering the output file contents for each attribute that is an aggregate
attribute_aggregate_template = %{}

# Template covering the output file contents for each attribute that is an aggregate of select of entity
attribute_aggregate_entity_select_template = %{}

# Template covering the output file contents for each attribute that is a select of entity
attribute_entity_select_template = %{}

# Template covering the output file contents for each attribute that is an entity
attribute_entity_template = %{<ownedAttribute xmi:type="uml:Property" xmi:id="<%= xmiid %>" name="<%= attr.name %>" visibility="public" isOrdered='<%= islist %>' isUnique='<%= isset %>' isLeaf='false' isStatic='false' isReadOnly='false' isDerived='false' isDerivedUnion='false' type="<%= domain_xmiid %>" aggregation="none" association="<%= assoc_xmiid %>" >
<% if lower == '0' %>
<lowerValue xmi:type="uml:LiteralInteger" xmi:id="<%= xmiid %>-lowerValue"/>
<% end %>
<% if lower != '0' and lower != '1' %>
<lowerValue xmi:type="uml:LiteralInteger" xmi:id="<%= xmiid %>-lowerValue"  value="<%= lower %>"/>
<% end %>
<% if upper != '1' %>
<upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="<%= xmiid %>-upperValue" value="<%= upper %>"/>
<% end %>
</ownedAttribute>}

# EXPLICIT ATTRIBUTE ENTITY Create Association Template
attribute_entity_association_template = %{<packagedElement xmi:type="uml:Association" xmi:id="<%= xmiid %>" name="" visibility='public' isLeaf='false' isAbstract='false' isDerived='false' memberEnd="<%= domain_xmiid %> <%= owner_xmiid %>">
<ownedEnd xmi:type="uml:Property" xmi:id="<%= xmiid + '-end' %>" type="<%= owner_xmiid %>" owningAssociation="_<%= xmiid %>" association="<%= xmiid %>" >
<upperValue xmi:type="uml:LiteralUnlimitedNatural" xmi:id="<%= xmiid %>-upperValue" value="*"/>
<lowerValue xmi:type="uml:LiteralInteger" xmi:id="<%= xmiid %>-lowerValue"/>
</ownedEnd>
</packagedElement>
}
 
# Template covering the output file contents for each attribute
attribute_template = %{}

# EXPLICIT ATTRIBUTE SIMPLE TYPE Template
attribute_builtin_template = %{
<% if datatype_hash[attr.domain] != nil %><ownedAttribute xmi:type="uml:Property" xmi:id="_<%= schema.name %>-<%= entity.name %>-<%= attr.name %>" name="<%= attr.name %>" visibility="public"><type xmi:type="uml:PrimitiveType" href="<%= datatype_hash[attr.domain] %>"/><% end %>	
<% if datatype_hash[attr.domain] == nil %><ownedAttribute xmi:type="uml:Property" xmi:id="_<%= schema.name %>-<%= entity.name %>-<%= attr.name %>" name="<%= attr.name %>" visibility="public" type="<%= attr.domain %>" ><% end %>	
 <% if attr.isOptional == TRUE %><lowerValue xmi:type="uml:LiteralInteger" xmi:id="_<%= schema.name %>-<%= entity.name %>-<%= attr.name %>_lowerValue"/><% end %>	
</ownedAttribute>}

# EXPLICIT ATTRIBUTE ENUM and TYPE Template
attribute_enum_type_template = %{<ownedAttribute xmi:type="uml:Property" xmi:id="_<%= schema.name %>-<%= entity.name %>-<%= attr.name %>" name="<%= attr.name %>" visibility="public" type="<%= type_xmiid %>"> 
<% if attr.isOptional == TRUE %>
<lowerValue xmi:type="uml:LiteralInteger" xmi:id="_<%= schema.name %>-<%= entity.name %>-<%= attr.name %>_lowerValue"/>
<% end %>
</ownedAttribute>}

# TYPE Template
type_template = %{<packagedElement xmi:type="uml:PrimitiveType" xmi:id="_<%= schema.name %>-<%= type.name %>" name="<%= type.name %>" >
<% if datatype_hash[type.domain] != nil %>
<generalization xmi:type="uml:Generalization" xmi:id="_supertype_<%= schema.name %>-<%= type.name %>">
<general xmi:type='uml:PrimitiveType' href="<%= datatype_hash[type.domain] %>" />
</generalization>
<% end %>	
<% if datatype_hash[type.domain] == nil %>
<generalization xmi:type="uml:Generalization" xmi:id="_supertype_<%= schema.name %>-<%= type.name %>" general="<%= type.domain %>"/>
<% end %>	
</packagedElement>}


#############################################################################################
# Set up list of schemas to process, input may be a repository containing schemas or a single schema
#############################################################################################

if mapinput.kind_of? EXPSM::Repository
	schema_list = mapinput.schemas
elsif mapinput.kind_of? EXPSM::SchemaDefinition
	schema_list = [mapinput]
else
	puts "ERROR : map_from_express input no Repository instance or Schema instance"
	exit
end

# Set up separate file for each schema 
	filename = 'Model.xmi'
	file = File.new(filename, "w")

# Evaluate and write file start template 
  res = ERB.new(overall_start_template)
  t = res.result(binding)
	file.puts t

for schema in schema_list

# Evaluate and write schema start template 
	res = ERB.new(schema_start_template)
	t = res.result(binding)
	file.puts t

# Handle type of building maps to UML Datatype
	type_list = schema.contents.find_all{ |e| e.instance_of? EXPSM::Type and e.isBuiltin}
	for type in type_list
		xmiid = '_' + schema.name + '-' + type.name
		res = ERB.new(type_template)
		t = res.result(binding)
		file.puts t
	end

# Handle enum maps to UML Enumeration
	enum_list = schema.contents.find_all{ |e| e.instance_of? EXPSM::TypeEnum }
	for enum in enum_list

# Evaluate and write enum start template 
		type_xmiid = '_' + schema.name + '-' + enum.name
		res = ERB.new(enum_start_template)
		t = res.result(binding)
		file.puts t

		enumitem_name_list = enum.items.scan(/\w+/)
		for enumitem in enumitem_name_list
			enumitem_xmiid = '_1_enumitem_' + schema.name + '-' + enum.name + '-' + enumitem
			res = ERB.new(enum_item_template)
			t = res.result(binding)
			file.puts t
		end

# Evaluate and write enum end template 
		res = ERB.new(enum_end_template)
		t = res.result(binding)
		file.puts t
	end

# Handle select maps to UML Interface 
	select_list = schema.contents.find_all{ |e| e.instance_of? EXPSM::TypeSelect }
	for select in select_list

# Evaluate and write select start template 
		xmiid = '_' + schema.name + '-' + select.name
		res = ERB.new(select_start_template)
		t = res.result(binding)
		file.puts t

		for superselect in select_list
			if superselect.selectitems_array.include?(select)
				xmiid = '_2_superselect_' + schema.name + '-' + select.name + '-' + superselect.name
				xmiid_supertype = '_' + schema.name + '-' + superselect.name
				res = ERB.new(supertype_template)
				t = res.result(binding)
				file.puts t
			end
		end

# Evaluate and write select end template 
		res = ERB.new(select_end_template)
		t = res.result(binding)
		file.puts t
	end
	
	entity_list = schema.contents.find_all{ |e| e.kind_of? EXPSM::Entity }

# Handle explicit attribute maps to UML Association (referenced from Class)
	for entity in entity_list
		attr_list = entity.attributes.find_all{ |e| e.kind_of? EXPSM::Explicit }
		for attr in attr_list
			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::Entity
				xmiid = '_1_association_' + schema.name + '-' + entity.name + '-' + attr.name
				owner_xmiid = '_' + schema.name + '-' + entity.name
				domain_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				res = ERB.new(attribute_entity_association_template)
				t = res.result(binding)
				file.puts t
			end
			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::TypeSelect
				xmiid = '_1_association_' + schema.name + '-' + entity.name + '-' + attr.name
				owner_xmiid = '_' + schema.name + '-' + entity.name
				domain_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				res = ERB.new(attribute_entity_association_template)
				t = res.result(binding)
				file.puts t
			end
		end
	end


# Handle entity maps to UML Class 
	for entity in entity_list
# Evaluate and write entity start template 
		xmiid = '_' + schema.name + '-' + entity.name
		res = ERB.new(entity_start_template)
		t = res.result(binding)
		file.puts t

		for supertype in entity.supertypes_array
			xmiid = '_2_supertype_' + schema.name + '-' + entity.name + '-' + supertype.name
			xmiid_supertype = '_' + schema.name + '-' + supertype.name
			res = ERB.new(supertype_template)
			t = res.result(binding)
			file.puts t
		end

		for select in select_list
			if select.selectitems_array.include?(entity)
				xmiid = '_2_selectitem_' + schema.name + '-' + entity.name + '-' + select.name
				xmiid_supplier = '_' + schema.name + '-' + select.name
				xmiid_client = '_' + schema.name + '-' + entity.name
				res = ERB.new(selectitem_entity_template)
				t = res.result(binding)
				file.puts t
			end
		end
		
		attr_list = entity.attributes.find_all{ |e| e.kind_of? EXPSM::Explicit }
		for attr in attr_list

			if attr.isBuiltin and !attr.instance_of? EXPSM::ExplicitAggregate
				res = ERB.new(attribute_builtin_template)
				t = res.result(binding)
				file.puts t
			end

			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::Type and !attr.instance_of? EXPSM::ExplicitAggregate
				type_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				res = ERB.new(attribute_enum_type_template)
				t = res.result(binding)
				file.puts t
			end

			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::TypeEnum and !attr.instance_of? EXPSM::ExplicitAggregate
				type_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				res = ERB.new(attribute_enum_type_template)
				t = res.result(binding)
				file.puts t
			end

			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::Entity 
				xmiid = '_2_attr_' + schema.name + '-' + entity.name + '-' + attr.name
				domain_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				assoc_xmiid = '_1_association_' + schema.name + '-' + entity.name + '-' + attr.name
				lower = '1'
				upper = '1'
				isset = 'true'
				islist = 'false'
				if attr.isOptional == TRUE
					lower = '0'
				end
				if attr.instance_of? EXPSM::ExplicitAggregate and attr.rank == 1
					upper = attr.dimensions[0].upper
					if upper == '?'
						upper = '*'
					end
					lower = attr.dimensions[0].lower
					if attr.dimensions[0].aggrtype == 'LIST' and !attr.dimensions[0].isUnique
						isset = 'false'
						islist = 'true'
					end
				end
				res = ERB.new(attribute_entity_template)
				t = res.result(binding)
				file.puts t
			end

			if NamedType.find_by_name( attr.domain ).kind_of? EXPSM::TypeSelect and !attr.instance_of? EXPSM::ExplicitAggregate
				xmiid = '_2_attr_' + schema.name + '-' + entity.name + '-' + attr.name
				domain_xmiid = '_' + schema.name + '-' + NamedType.find_by_name( attr.domain ).name
				assoc_xmiid = '_1_association_' + schema.name + '-' + entity.name + '-' + attr.name
				res = ERB.new(attribute_entity_template)
				t = res.result(binding)
				file.puts t
			end

			if attr.redeclare_entity
				puts "#WARNING: '" + entity.name + ' ' + attr.name + "' Attribute redeclaration may need hand editing"
			end

			if attr.instance_of? EXPSM::ExplicitAggregate
			else
			end
		end


# Evaluate and write entity end template 
		res = ERB.new(entity_end_template)
		t = res.result(binding)
		file.puts t
	end


	res = ERB.new(schema_end_template)
	t = res.result(binding)
	file.puts t

end

res = ERB.new(overall_end_template)
t = res.result(binding)
file.puts t
end