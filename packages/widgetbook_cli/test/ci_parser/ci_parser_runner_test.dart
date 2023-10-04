import 'package:args/args.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:test/test.dart';

import '../../bin/ci_parser/ci_parser.dart';
import '../../bin/git/repository.dart';
import '../../bin/models/models.dart';
import '../mocks/command_mocks.dart';

const repositoryName = 'widgetbook';
const actorName = 'John Doe';

void main() {
  late CiParserRunner sut;
  late ArgResults argResults;
  late Repository repository;
  late CiWrapper ciWrapper;
  late Platform platform;

  setUp(() async {
    argResults = MockArgResults();
    repository = MockRepository();
    ciWrapper = MockCiWrapper();
    platform = MockPlatform();

    sut = CiParserRunner(
      argResults: argResults,
      repository: repository,
      ciWrapper: ciWrapper,
      platform: platform,
    );
  });

  group('$CiParserRunner', () {
    test(
      'expect instance of $ArgResults',
      () async {
        expect(sut.argResults, equals(argResults));
      },
    );

    test(
      'expect instance of $MockRepository',
      () async {
        expect(sut.repository, equals(repository));
      },
    );

    test(
      'returns $CiArgs from $LocalParser',
      () async {
        when(() => ciWrapper.isCI()).thenReturn(false);
        when(() => repository.user).thenAnswer((_) async => actorName);
        when(() => repository.name).thenAnswer((_) async => repositoryName);

        final sut = CiParserRunner(
          argResults: argResults,
          repository: repository,
          ciWrapper: ciWrapper,
        );

        final ciArgs = await sut.getParser()?.getCiArgs();

        expect(ciArgs?.vendor, 'Local');
        expect(ciArgs?.actor, actorName);
        expect(ciArgs?.repository, repositoryName);
      },
    );

    test(
      'returns $CiArgs from $GitLabParser',
      () async {
        when(() => ciWrapper.isCI()).thenReturn(true);
        when(() => ciWrapper.isGitLab()).thenReturn(true);
        when(
          () => platform.environment,
        ).thenReturn({
          'CI_PROJECT_NAME': repositoryName,
          'GITLAB_USER_NAME': actorName,
        });

        final ciArgs = await sut.getParser()?.getCiArgs();

        expect(ciArgs?.actor, actorName);
        expect(ciArgs?.repository, repositoryName);
        expect(ciArgs?.vendor, 'GitLab');
      },
    );
    test(
      'returns $CiArgs from $GitHubParser',
      () async {
        when(() => ciWrapper.isCI()).thenReturn(true);
        when(() => ciWrapper.isGithub()).thenReturn(true);
        when(() => ciWrapper.isBitBucket()).thenReturn(false);
        when(() => ciWrapper.isGitLab()).thenReturn(false);
        when(() => ciWrapper.isAzure()).thenReturn(false);
        when(
          () => platform.environment,
        ).thenReturn({
          'GITHUB_REPOSITORY': repositoryName,
          'GITHUB_ACTOR': actorName,
        });

        final ciArgs = await sut.getParser()?.getCiArgs();

        expect(ciArgs?.actor, actorName);
        expect(ciArgs?.repository, repositoryName);
        expect(ciArgs?.vendor, 'GitHub');
      },
    );

    test(
      'returns $CiArgs from $AzureParser',
      () async {
        when(() => ciWrapper.isCI()).thenReturn(true);
        when(() => ciWrapper.isAzure()).thenReturn(true);
        when(() => ciWrapper.isBitBucket()).thenReturn(false);
        when(() => ciWrapper.isGitLab()).thenReturn(false);
        when(() => ciWrapper.isGithub()).thenReturn(false);
        when(
          () => platform.environment,
        ).thenReturn({
          'Build.Repository.Name': repositoryName,
          'Agent.Name': actorName,
        });

        final ciArgs = await sut.getParser()?.getCiArgs();

        expect(ciArgs?.actor, actorName);
        expect(ciArgs?.repository, repositoryName);
        expect(ciArgs?.vendor, 'Azure');
      },
    );

    test(
      'returns $CiArgs from $BitbucketParser',
      () async {
        when(() => ciWrapper.isCI()).thenReturn(true);
        when(() => ciWrapper.isBitBucket()).thenReturn(true);
        when(() => ciWrapper.isAzure()).thenReturn(false);
        when(() => ciWrapper.isGitLab()).thenReturn(false);
        when(() => ciWrapper.isGithub()).thenReturn(false);
        when(
          () => platform.environment,
        ).thenReturn({
          'BITBUCKET_REPO_FULL_NAME': repositoryName,
          'BITBUCKET_STEP_TRIGGERER_UUID': actorName,
        });

        final ciArgs = await sut.getParser()?.getCiArgs();

        expect(ciArgs?.actor, actorName);
        expect(ciArgs?.repository, repositoryName);
        expect(ciArgs?.vendor, 'Bitbucket');
      },
    );
  });
}
