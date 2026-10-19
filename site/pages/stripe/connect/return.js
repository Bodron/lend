export async function getServerSideProps() {
  return { redirect: { destination: "/account?stripe=return", permanent: false } };
}

export default function StripeConnectReturn() {
  return null;
}
