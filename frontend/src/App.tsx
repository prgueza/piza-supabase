import LOGO from "./assets/piza-logo.png";
import {
  EuiEmptyPrompt,
  EuiLink,
  EuiPageTemplate,
  EuiTitle,
  EuiImage,
} from "@elastic/eui";

export const App = () => {
  return (
    <EuiPageTemplate>
      <EuiPageTemplate.EmptyPrompt
        title={<EuiImage src={LOGO} alt="piza logo" size="l" />}
      >
        <EuiEmptyPrompt
          body={
            <EuiTitle>
              <p>Welcome to the Piza™ frontend application bootstrap</p>
            </EuiTitle>
          }
          footer={
            <>
              <EuiTitle size="xxs">
                <h4>Ready for the challenge?</h4>
              </EuiTitle>
              <EuiLink
                href="https://github.com/prgueza/piza-supabase"
                target="_blank"
              >
                Read the instructions
              </EuiLink>
            </>
          }
        />
      </EuiPageTemplate.EmptyPrompt>
    </EuiPageTemplate>
  );
};
