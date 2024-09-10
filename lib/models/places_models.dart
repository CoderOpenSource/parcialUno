// To parse this JSON data, do
//
//     final placesResponse = placesResponseFromJson(jsonString);

import 'dart:convert';

class PlacesResponse {
  final String? type;
  //final List<String>? query;
  final List<Feature>? features;
  final String? attribution;

  PlacesResponse({
    this.type,
    //this.query,
    this.features,
    this.attribution,
  });

  factory PlacesResponse.fromRawJson(String str) =>
      PlacesResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PlacesResponse.fromJson(Map<String, dynamic> json) => PlacesResponse(
        type: json["type"],
        //  query: json["query"] == null
        //    ? []
        //  : List<String>.from(json["query"]!.map((x) => x)),
        features: json["features"] == null
            ? []
            : List<Feature>.from(
                json["features"]!.map((x) => Feature.fromJson(x))),
        attribution: json["attribution"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
        //"query": query == null ? [] : List<dynamic>.from(query!.map((x) => x)),
        "features": features == null
            ? []
            : List<dynamic>.from(features!.map((x) => x.toJson())),
        "attribution": attribution,
      };
}

class Feature {
  final String? id;
  final String? type;
  final List<String>? placeType;
  final Properties? properties;
  final String? textEs;
  final String? placeNameEs;
  final String? text;
  final String? placeName;
  final List<double>? center;
  final Geometry? geometry;
  final List<Context>? context;

  Feature({
    this.id,
    this.type,
    this.placeType,
    this.properties,
    this.textEs,
    this.placeNameEs,
    this.text,
    this.placeName,
    this.center,
    this.geometry,
    this.context,
  });

  factory Feature.fromRawJson(String str) => Feature.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
        id: json["id"],
        type: json["type"],
        placeType: json["place_type"] == null
            ? []
            : List<String>.from(json["place_type"]!.map((x) => x)),
        properties: json["properties"] == null
            ? null
            : Properties.fromJson(json["properties"]),
        textEs: json["text_es"],
        placeNameEs: json["place_name_es"],
        text: json["text"],
        placeName: json["place_name"],
        center: json["center"] == null
            ? []
            : List<double>.from(json["center"]!.map((x) => x?.toDouble())),
        geometry: json["geometry"] == null
            ? null
            : Geometry.fromJson(json["geometry"]),
        context: json["context"] == null
            ? []
            : List<Context>.from(
                json["context"]!.map((x) => Context.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "place_type": placeType == null
            ? []
            : List<dynamic>.from(placeType!.map((x) => x)),
        "properties": properties?.toJson(),
        "text_es": textEs,
        "place_name_es": placeNameEs,
        "text": text,
        "place_name": placeName,
        "center":
            center == null ? [] : List<dynamic>.from(center!.map((x) => x)),
        "geometry": geometry?.toJson(),
        "context": context == null
            ? []
            : List<dynamic>.from(context!.map((x) => x.toJson())),
      };
}

class Context {
  final Id? id;
  final Wikidata? wikidata;
  final MapboxId? mapboxId;
  final Text? textEs;
  final Language? languageEs;
  final Text? text;
  final Language? language;
  final ShortCode? shortCode;

  Context({
    this.id,
    this.wikidata,
    this.mapboxId,
    this.textEs,
    this.languageEs,
    this.text,
    this.language,
    this.shortCode,
  });

  factory Context.fromRawJson(String str) => Context.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Context.fromJson(Map<String, dynamic> json) => Context(
        id: idValues.map[json["id"]],
        wikidata: wikidataValues.map[json["wikidata"]],
        mapboxId: mapboxIdValues.map[json["mapbox_id"]],
        textEs: textValues.map[json["text_es"]],
        languageEs: languageValues.map[json["language_es"]],
        text: textValues.map[json["text"]],
        language: languageValues.map[json["language"]],
        shortCode: shortCodeValues.map[json["short_code"]],
      );

  Map<String, dynamic> toJson() => {
        "id": idValues.reverse[id],
        "wikidata": wikidataValues.reverse[wikidata],
        "mapbox_id": mapboxIdValues.reverse[mapboxId],
        "text_es": textValues.reverse[textEs],
        "language_es": languageValues.reverse[languageEs],
        "text": textValues.reverse[text],
        "language": languageValues.reverse[language],
        "short_code": shortCodeValues.reverse[shortCode],
      };
}

enum Id { PLACE_2066462, REGION_42014, COUNTRY_8734 }

final idValues = EnumValues({
  "country.8734": Id.COUNTRY_8734,
  "place.2066462": Id.PLACE_2066462,
  "region.42014": Id.REGION_42014
});

enum Language { ES }

final languageValues = EnumValues({"es": Language.ES});

enum MapboxId {
  D_X_JU_OM1_IE_H_BS_YZP_IN_GDL,
  D_X_JU_OM1_IE_H_BS_YZPW_QJ_Q,
  D_X_JU_OM1_IE_H_BS_YZP_JA_DQ
}

final mapboxIdValues = EnumValues({
  "dXJuOm1ieHBsYzpwQjQ": MapboxId.D_X_JU_OM1_IE_H_BS_YZPW_QJ_Q,
  "dXJuOm1ieHBsYzpINGdl": MapboxId.D_X_JU_OM1_IE_H_BS_YZP_IN_GDL,
  "dXJuOm1ieHBsYzpJaDQ": MapboxId.D_X_JU_OM1_IE_H_BS_YZP_JA_DQ
});

enum ShortCode { BO_S, BO }

final shortCodeValues =
    EnumValues({"bo": ShortCode.BO, "BO-S": ShortCode.BO_S});

enum Text { SANTA_CRUZ_DE_LA_SIERRA, DEPARTAMENTO_DE_SANTA_CRUZ, BOLIVIA }

final textValues = EnumValues({
  "Bolivia": Text.BOLIVIA,
  "Departamento de Santa Cruz": Text.DEPARTAMENTO_DE_SANTA_CRUZ,
  "Santa Cruz de la Sierra": Text.SANTA_CRUZ_DE_LA_SIERRA
});

enum Wikidata { Q170688, Q235106, Q750 }

final wikidataValues = EnumValues({
  "Q170688": Wikidata.Q170688,
  "Q235106": Wikidata.Q235106,
  "Q750": Wikidata.Q750
});

class Geometry {
  final List<double>? coordinates;
  final String? type;

  Geometry({
    this.coordinates,
    this.type,
  });

  factory Geometry.fromRawJson(String str) =>
      Geometry.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Geometry.fromJson(Map<String, dynamic> json) => Geometry(
        coordinates: json["coordinates"] == null
            ? []
            : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "coordinates": coordinates == null
            ? []
            : List<dynamic>.from(coordinates!.map((x) => x)),
        "type": type,
      };
}

class Properties {
  final String? foursquare;
  final bool? landmark;
  final String? address;
  final String? category;

  Properties({
    this.foursquare,
    this.landmark,
    this.address,
    this.category,
  });

  factory Properties.fromRawJson(String str) =>
      Properties.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Properties.fromJson(Map<String, dynamic> json) => Properties(
        foursquare: json["foursquare"],
        landmark: json["landmark"],
        address: json["address"],
        category: json["category"],
      );

  Map<String, dynamic> toJson() => {
        "foursquare": foursquare,
        "landmark": landmark,
        "address": address,
        "category": category,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
