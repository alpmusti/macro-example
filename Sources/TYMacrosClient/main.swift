import TYMacros

//enum Constant {
//    case influencer
//
//    var value: String {
//        switch self {
//        case .influencer:
//            return "https://trendyol.com"
//        }
//    }
//}
//
//@EndpointMacro(args: [
//    .init(caseName: "fetchA", baseUrl: "{Constant.influencer.value}", path: "/downloads"),
//    .init(caseName: "fetchB", baseUrl: "Constant.influencer.value", path: "/downloads")
//])
//enum SocialEndpoint {
//    case fetchA
//    case fetchB
//}

@ABConfigurables
public struct ABTestDefinitions {
    private init() { }
    
    @ABConfig(args: ABConfigArguments(firebaseDimension: "ios_abtest_1"))
    public struct SocialAB {
    }
    
    @ABConfig(args: ABConfigArguments(firebaseDimension: "ios_abtest_2", isLegacyConfig: true, isCommonConfig: true))
    public struct HomepageAB {
    }
}
