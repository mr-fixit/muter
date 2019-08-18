import Quick
import Nimble
import Foundation
import TestingExtensions
@testable import muterCore

class ReporterSpec: QuickSpec {
    override func spec() {

        let outcomes = [
            MutationTestOutcome(testSuiteOutcome: .passed,
                                mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/project/file3.swift", position: .firstPosition),
                                operatorDescription: "changed from != to ==",
                                originalProjectDirectoryUrl: URL(string: "/user/project")!
            )
        ]

        describe("text reporter") {
            it("returns the report in text format") {
                expect(Reporter.plainText.generateReport(from: outcomes)).toNot(beEmpty())
            }
        }

        describe("xcode reporter") {
            it("returns the report in xcode format") {
                let outcomes = outcomes + [MutationTestOutcome(testSuiteOutcome: .failed,
                                                               mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/project/file4.swift", position: .firstPosition),
                                                               operatorDescription: "changed from == to !=",
                                                               originalProjectDirectoryUrl: URL(string: "/user/project")!),
                                           MutationTestOutcome(testSuiteOutcome: .passed,
                                                               mutationPoint: MutationPoint(mutationOperatorId: .negateConditionals, filePath: "/tmp/project/file5.swift", position: .firstPosition),
                                                               operatorDescription: "changed from == to !=",
                                                               originalProjectDirectoryUrl: URL(string: "/user/project")!)]

                expect(Reporter.xcode.generateReport(from: outcomes)) == """
                /user/project/file3.swift:0:0: warning: Your test suite did not kill this mutant: changed from != to ==
                /user/project/file5.swift:0:0: warning: Your test suite did not kill this mutant: changed from == to !=
                """
            }
        }

        describe("json reporter") {
            it("returns the report in json format") {

                let json = Reporter.json.generateReport(from: outcomes)

                guard let data = json.data(using: .utf8),
                    let actualReport = try? JSONDecoder().decode(MuterTestReport.self, from: data) else {
                        fail("Expected a valid JSON object, but didn't get one")
                        return
                }

                // The reports differ and can't be equated easily as we do not persist the path of a file report.
                // Basically, when we deserialize it, it's missing a field (`path`).
                expect(actualReport.totalAppliedMutationOperators) == 1
                expect(actualReport.fileReports.first?.fileName) == "file3.swift"
            }
        }
    }
}
